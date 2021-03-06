require 'thread'
require 'time'

module Grad; class Watcher
  attr_reader :cpu, :cpu_thread, :loadavg, :loadavg_thread, :memory, :memory_thread, :network, :network_thread, :resp_time_mediana
  attr_accessor :network_port, :launcher

  def initialize(sleep_sec = 2)
    @sleep_sec = sleep_sec
    @network_port = '80'
    @cpu = Hash.new
    @loadavg = Hash.new
    @memory = Hash.new
    @network = Hash.new
    @resp_stats = {}
    @resp_time_mediana = 0
    watch_cpu
    watch_loadavg
    watch_memory
    watch_network
    watch_launcher
  end

  # print meminfo in similar format as top does
  def watch_memory
    @memory_thread = Thread.new do
    proc_meminfo = File.open('/proc/meminfo', 'r')
      while true
        proc_meminfo.reopen('/proc/meminfo', 'r').each_line do |line|
          case line 
          when /^MemTotal:.*/
            @memory[:m_total] = line.split(/\s+/)[1]
            @memory[:units] ||= line.split(/\s+/)[2]
          when /^MemFree:.*/
            @memory[:m_free] = line.split(/\s+/)[1]
          when /^Buffers:.*/
            @memory[:m_buffers] = line.split(/\s+/)[1]
          when /^SwapTotal:.*/
            @memory[:s_total] = line.split(/\s+/)[1]
          when /^SwapFree:.*/
            @memory[:s_free] = line.split(/\s+/)[1]
          when /^Cached:.*/
            @memory[:s_cached] = line.split(/\s+/)[1]
          end
        end
        @memory[:m_used] = @memory[:m_total].to_i - @memory[:m_free].to_i
        @memory[:s_used] = @memory[:s_total].to_i - @memory[:s_free].to_i
        sleep @sleep_sec
      end
    end
  end

  def watch_loadavg
    @loadavg_thread = Thread.new do
    proc_loadavg = File.open('/proc/loadavg', 'r')
      while true do
        loadavg_a = proc_loadavg.reopen('/proc/loadavg', 'r').first.split(/\s+/)
        @loadavg = { :min1 => loadavg_a[0], :min5 => loadavg_a[1], :min15 => loadavg_a[2] }
        sleep @sleep_sec
      end
    end
  end

  def watch_cpu
    stat_curr = Array.new
    stat_prev = Array.new
    @cpu_thread = Thread.new do
    proc_stat = File.open('/proc/stat', 'r')
      while true do
        stat_curr = proc_stat.reopen('/proc/stat', 'r').first.split(/\s+/)
        stat_curr[0] = '0'
        states = { :us => 1, :ni => 2, :sy => 3, :id => 4, :wa => 5, :hi => 6, :si => 7, :st => 8 }
        if stat_prev.empty?
          stat_prev = stat_curr
          sleep @sleep_sec
          next
        end
        next if stat_curr == stat_prev

        total_curr = total_prev = 0
        stat_curr.each {|n| total_curr += n.to_f}
        stat_prev.each {|n| total_prev += n.to_f}
        total_diff = total_curr - total_prev

        states.each do |name, pos|
          val_diff = stat_curr[pos].to_f - stat_prev[pos].to_f
          val_calc = (val_diff / total_diff).to_f * 100.to_f
          @cpu[name] = val_calc.round(1)
        end
        stat_prev = stat_curr
        sleep @sleep_sec
      end
    end
  end

  def watch_network
    @network_thread = Thread.new do
    port_hex = "%04X" % @network_port
    proc_net_tcp = File.open('/proc/net/tcp', 'r')
      while true
        @network[:tcp_conn] = @network[:tcp_conn_port] = 0
        proc_net_tcp.reopen('/proc/net/tcp', 'r').each_line do |line|
          @network[:tcp_conn] += 1
          @network[:tcp_conn_port] += 1 if line.split(/\s+/)[3] =~ /.*:#{port_hex}/
        end
        sleep @sleep_sec
      end   
    end
  end

  def watch_launcher
    Thread.new do     
      while sleep @sleep_sec
        next if !@launcher
        next if @launcher.resp_t.empty?

        # process launcher response vals
        until @launcher.resp_t.empty? do
          r = @launcher.resp_t.pop.round(3)
          @resp_stats.key?(r) ? @resp_stats[r] = @resp_stats[r] + 1 : @resp_stats[r] = 1
        end

        # caclucate response (mediana)
        @resp_time_mediana = calc_resp_mediana(@resp_stats)
      end
    end
  end

=begin
  def calc_resp_every(n)
    next_update ||= Time.now + n

    resp_hash = {}
    if next_update < Time.now
      resp_hash = @resp_stats.dup

    end
  end
=end

  def calc_resp_mediana(resp_hash)
    half = resp_hash.values.inject(0) {|sum, i| sum + i} / 2
    now_at = 0
    resp_hash.to_a.sort.each do |i|
      now_at = now_at + i[1]
      return i[0] if now_at > half
    end
  end

end; end


