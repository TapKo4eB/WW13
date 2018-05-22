q// Singleton instance of game_controller_new, setup in world.New()
var/global/processScheduler/processScheduler

/processScheduler
	parent_type = /datum
	// Processes known by the scheduler
	var/tmp/process/list/processes = list()

	// Processes that are currently running
	var/tmp/process/list/running = list()

	// Processes that are idle
	var/tmp/process/list/idle = list()

	// Processes that are queued to run
	var/tmp/process/list/queued = list()

	// Process name -> process object map
	var/tmp/process/list/nameToProcessMap = list()

	// Process last queued times (world time)
	var/tmp/process/list/last_queued = list()

	// Process last start times (real time)
	var/tmp/process/list/last_start = list()

	// Process last run durations
	var/tmp/process/list/last_run_time = list()

	// Per process list of the last 20 durations
	var/tmp/process/list/last_twenty_run_times = list()

	// Process highest run time
	var/tmp/process/list/highest_run_time = list()

	// How long to sleep between runs (set to tick_lag in New)
	var/tmp/scheduler_sleep_interval = 0

	// Controls whether the scheduler is running or not
	var/tmp/isRunning = FALSE

	// Setup for these processes will be deferred until all the other processes are set up.
	var/tmp/list/deferredSetupList = new

	var/tmp/currentTick = 0

	var/tmp/timeAllowance = 0

	var/tmp/cpuAverage = 0

	var/tmp/timeAllowanceMax = 0

/processScheduler/New()
	..()
	// When the process scheduler is first new'd, tick_lag may be wrong, so these
	//  get re-initialized when the process scheduler is started.
	// (These are kept here for any processes that decide to process before round start)
	scheduler_sleep_interval = world.tick_lag
	timeAllowance = world.tick_lag * 0.50
	timeAllowanceMax = world.tick_lag

/**
 * deferSetupFor
 * @param path processPath
 * If a process needs to be initialized after everything else, add it to
 * the deferred setup list. On goonstation, only the ticker needs to have
 * this treatment.
 */
/processScheduler/proc/deferSetupFor(var/processPath)
	if (!(processPath in deferredSetupList))
		deferredSetupList += processPath

/processScheduler/proc/setup()
	// There can be only one
	if (processScheduler && processScheduler != src)
		del(src)
		return FALSE

	var/process
	// Add all the processes we can find, except for the ticker
	for (process in subtypesof(/process))
		if (!(process in deferredSetupList))
			addProcess(new process(src))

	for (process in deferredSetupList)
		addProcess(new process(src))

/processScheduler/proc/start()
	isRunning = TRUE
	// tick_lag will have been set by now, so re-initialize these
	scheduler_sleep_interval = world.tick_lag
	timeAllowance = world.tick_lag * 0.50
	timeAllowanceMax = world.tick_lag
	updateStartDelays()
	spawn(0)
		process()

/processScheduler/proc/process()
	updateCurrentTickData()

	for(var/i=world.tick_lag,i<world.tick_lag*50,i+=world.tick_lag)
		spawn(i) updateCurrentTickData()
	while (isRunning)
		// Hopefully spawning this for 50 ticks in the future will make it the first thing in the queue.
		spawn(world.tick_lag*50) updateCurrentTickData()
		checkRunningProcesses()
		queueProcesses()
		runQueuedProcesses()
		sleep(scheduler_sleep_interval)

	// handle hung fake subsystems: restartProcess() only restarts subsystems if they're really dead
	for (var/name in last_ran_subsystem)
		restartProcess(name)

/processScheduler/proc/stop()
	isRunning = FALSE

/processScheduler/proc/checkRunningProcesses()
	for(var/process/p in running)
		p.update()

		if (isnull(p)) // Process was killed
			continue

		var/status = p.getStatus()
		var/previousStatus = p.getPreviousStatus()

		// Check status changes
		if (status != previousStatus)
			//Status changed.
			switch(status)
				if (PROCESS_STATUS_PROBABLY_HUNG)
					message_admins("Process '[p.name]' may be hung.")
				if (PROCESS_STATUS_HUNG)
					message_admins("Process '[p.name]' is hung and will be restarted.")

/processScheduler/proc/queueProcesses()
	for(var/process/p in processes)
		// Don't double-queue, don't queue running processes
		if (p.disabled || p.running || p.queued || !p.idle)
			continue

		if (ticker && !p.fires_at_gamestates.Find(ticker.current_state))
			continue

		// If the process should be running by now, go ahead and queue it
		if (world.time >= last_queued[p] + p.schedule_interval)
			setQueuedProcessState(p)

/processScheduler/proc/runQueuedProcesses()
	for(var/process/p in queued)
		if (!p.subsystem)
			runProcess(p)

/processScheduler/proc/addProcess(var/process/process)
	processes.Add(process)
	process.idle()
	idle.Add(process)

	// init recordkeeping vars
	last_start.Add(process)
	last_start[process] = 0
	last_run_time.Add(process)
	last_run_time[process] = 0
	last_twenty_run_times.Add(process)
	last_twenty_run_times[process] = list()
	highest_run_time.Add(process)
	highest_run_time[process] = 0

	// init starts and stops record starts
	recordStart(process, 0)
	recordEnd(process, 0)

	// Set up process
	process.setup()

	// Subsystem? make the process run independently and recover quickly if it hangs
	if (process.subsystem)
		DO_INTERNAL_SUBSYSTEM(process)

	// Save process in the name -> process map
	nameToProcessMap[process.name] = process

/processScheduler/proc/replaceProcess(var/process/oldProcess, var/process/newProcess)
	processes.Remove(oldProcess)
	processes.Add(newProcess)

	newProcess.idle()
	idle.Remove(oldProcess)
	running.Remove(oldProcess)
	queued.Remove(oldProcess)
	idle.Add(newProcess)

	last_start.Remove(oldProcess)
	last_start.Add(newProcess)
	last_start[newProcess] = 0

	last_run_time.Add(newProcess)
	last_run_time[newProcess] = last_run_time[oldProcess]
	last_run_time.Remove(oldProcess)

	last_twenty_run_times.Add(newProcess)
	last_twenty_run_times[newProcess] = last_twenty_run_times[oldProcess]
	last_twenty_run_times.Remove(oldProcess)

	highest_run_time.Add(newProcess)
	highest_run_time[newProcess] = highest_run_time[oldProcess]
	highest_run_time.Remove(oldProcess)

	recordStart(newProcess, 0)
	recordEnd(newProcess, 0)

	nameToProcessMap[newProcess.name] = newProcess

/processScheduler/proc/updateStartDelays()
	for(var/process/p in processes)
		if (p.start_delay)
			last_queued[p] = world.time - p.start_delay

/processScheduler/proc/runProcess(var/process/process)
	spawn(0)
		process.process()

/processScheduler/proc/processStarted(var/process/process)
	setRunningProcessState(process)
	recordStart(process)

/processScheduler/proc/processFinished(var/process/process)
	setIdleProcessState(process)
	recordEnd(process)

/processScheduler/proc/setIdleProcessState(var/process/process)
	if (process in running)
		running -= process
	if (process in queued)
		queued -= process
	if (!(process in idle))
		idle += process

/processScheduler/proc/setQueuedProcessState(var/process/process)
	if (process in running)
		running -= process
	if (process in idle)
		idle -= process
	if (!(process in queued))
		queued += process

	// The other state transitions are handled internally by the process.
	process.queued()

/processScheduler/proc/setRunningProcessState(var/process/process)
	if (process in queued)
		queued -= process
	if (process in idle)
		idle -= process
	if (!(process in running))
		running += process

/processScheduler/proc/recordStart(var/process/process, var/time = null)
	if (isnull(time))
		time = TimeOfGame
		last_queued[process] = world.time
		last_start[process] = time
	else
		last_queued[process] = (time == 0 ? 0 : world.time)
		last_start[process] = time

/processScheduler/proc/recordEnd(var/process/process, var/time = null)
	if (isnull(time))
		time = TimeOfGame

	var/lastRunTime = time - last_start[process]

	if (lastRunTime < 0)
		lastRunTime = 0

	recordRunTime(process, lastRunTime)

/**
 * recordRunTime
 * Records a run time for a process
 */
/processScheduler/proc/recordRunTime(var/process/process, time)
	last_run_time[process] = time
	if (time > highest_run_time[process])
		highest_run_time[process] = time

	var/list/lastTwenty = last_twenty_run_times[process]
	if (lastTwenty.len == 20)
		lastTwenty.Cut(1, 2)
	lastTwenty.len++
	lastTwenty[lastTwenty.len] = time

/**
 * averageRunTime
 * returns the average run time (over the last 20) of the process
 */
/processScheduler/proc/averageRunTime(var/process/process)
	var/lastTwenty = last_twenty_run_times[process]

	var/t = 0
	var/c = 0
	for(var/time in lastTwenty)
		t += time
		c++

	if (c > 0)
		return t / c
	return c

/processScheduler/proc/getProcessLastRunTime(var/process/process)
	return last_run_time[process]

/processScheduler/proc/getProcessHighestRunTime(var/process/process)
	return highest_run_time[process]

/processScheduler/proc/getStatusData()
	var/list/data = new

	for (var/process/p in processes)
		data.len++
		data[data.len] = p.getContextData()

	return data

/processScheduler/proc/getProcessCount()
	return processes.len

/processScheduler/proc/hasProcess(var/processName as text)
	if (nameToProcessMap[processName])
		return TRUE

/processScheduler/proc/killProcess(var/processName as text)
	restartProcess(processName)

/processScheduler/proc/restartProcess(var/processName as text)
	if (subsystems.Find(processName))
		if (hasProcess(processName))
			var/process/instance = nameToProcessMap[processName]
			var/time_since_last_run = world.time - last_ran_subsystem[processName]
			if (time_since_last_run/10 >= instance.schedule_interval)
				DO_INTERNAL_SUBSYSTEM(instance)
	else if (hasProcess(processName))
		var/process/oldInstance = nameToProcessMap[processName]
		var/process/newInstance = new oldInstance.type(src)
		newInstance._copyStateFrom(oldInstance)
		replaceProcess(oldInstance, newInstance)
		oldInstance.kill()

/processScheduler/proc/enableProcess(var/processName as text)
	if (hasProcess(processName))
		var/process/process = nameToProcessMap[processName]
		process.enable()

/processScheduler/proc/disableProcess(var/processName as text)
	if (hasProcess(processName))
		var/process/process = nameToProcessMap[processName]
		process.disable()

/processScheduler/proc/getCurrentTickElapsedTime()
	if (world.time > currentTick)
		updateCurrentTickData()
		return 0
	else
		return TimeOfTick

/processScheduler/proc/updateCurrentTickData()
	if (world.time > currentTick)
		// New tick!
		currentTick = world.time
		updateTimeAllowance()
		cpuAverage = (world.cpu + cpuAverage + cpuAverage) / 3

/processScheduler/proc/updateTimeAllowance()
	// Time allowance goes down linearly with world.cpu.
	var/tmp/error = cpuAverage - 100
	var/tmp/timeAllowanceDelta = SIMPLE_SIGN(error) * -0.5 * world.tick_lag * max(0, 0.001 * abs(error))

	//timeAllowance = world.tick_lag * min(1, 0.5 * ((200/max(1,cpuAverage)) - 1))
	timeAllowance = min(timeAllowanceMax, max(0, timeAllowance + timeAllowanceDelta))

/processScheduler/proc/statProcesses()
	if (!isRunning)
		stat("Processes", "Scheduler not running")
		return
	stat("Processes", "[processes.len] (R [running.len] / Q [queued.len] / I [idle.len])")
	stat(null, "[round(cpuAverage, 0.1)] CPU, [round(timeAllowance, 0.1)/10] TA")
	for(var/process/p in processes)
		p.statProcess()

/processScheduler/proc/htmlProcesses()
	. = "<html><body>"
	if (!isRunning)
		. += "<p><big>Processes: Scheduler not running</big></p>"
		return
	. += "<p><big>Processes: [processes.len] (R [running.len] / Q [queued.len] / I [idle.len])</big></p>"
	. += "<p>[round(cpuAverage, 0.1)] CPU, [round(timeAllowance, 0.1)/10] TA</p>"
	for(var/process/p in processes)
		. += "<p><b>[p.name]</b>: [p.htmlProcess()]</p>"
	. += "</body></html>"

/processScheduler/proc/getProcess(var/process_name)
	return nameToProcessMap[process_name]