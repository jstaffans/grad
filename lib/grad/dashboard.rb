require 'curses'
module Grad; class Dashboard
  attr_accessor :host, :port, :host_header, :log_dst, :format
  include Curses

  def initialize(watcher_obj)
    init_screen
    @watcher_obj = watcher_obj
  end

  def print_out
    setpos(0, 0)

    # print header
    addstr("=============== Grad Dashboard ===============\n")
    addstr("Target Host: \
#{@host}:#{@port}, \
Host header: #{@host_header}\n\
Input Log Format: \"#{@format}\"\n\
LogTo: #{@log_dst}\n\n")

    # print vehicle stats
    #
    addstr("\nGrad vehicle stats>\n")

    # print load average stats
    addstr("load average: \
#{@watcher_obj.loadavg[:min1]}, \
#{@watcher_obj.loadavg[:min5]}, \
#{@watcher_obj.loadavg[:min15]}\n")

    # print cpu stats
    addstr("Cpu(s): \
#{@watcher_obj.cpu[:us]}%us, \
#{@watcher_obj.cpu[:sy]}%sy, \
#{@watcher_obj.cpu[:ni]}%ni, \
#{@watcher_obj.cpu[:id]}%id, \
#{@watcher_obj.cpu[:wa]}%wa, \
#{@watcher_obj.cpu[:hi]}%hi, \
#{@watcher_obj.cpu[:si]}%si, \
#{@watcher_obj.cpu[:st]}%st\n")

    # print network stats
    addstr("Network: \
#{@watcher_obj.network[:tcp_conn]} tcp total, \
#{@watcher_obj.network[:tcp_conn_port]} tcp port #{@port} total\n")

    # print launcher stats
    #
    addstr("\nGrad launcher stats>\n")
    addstr("\
Input_Q: #{@watcher_obj.launcher.input_q.size},\n\
Run_Q: #{@watcher_obj.launcher.slots_used}\n\
Req_done: #{@watcher_obj.launcher.done_q.size}\n\
Req_fail: #{@watcher_obj.launcher.fail_q.size}\n\
Req_drop: #{@watcher_obj.launcher.drop_q.size}\n\
")

    # print target stats
    #
    addstr("\nGrad target stats>\n")
    addstr("\
Resp time (med): #{@watcher_obj.resp_time_mediana},\n\
")

    # refresh screen
    #
    refresh
  end

  def stop
    close_screen
  end
end; end
