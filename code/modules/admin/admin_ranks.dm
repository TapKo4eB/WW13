var/list/admin_ranks = list()								//list of all ranks with associated rights

//load our rank - > rights associations
/proc/load_admin_ranks()
	admin_ranks.Cut()

	var/previous_rights = FALSE

	//load text from file
	var/list/Lines = file2list("config/admin_ranks.txt")

	//process each line seperately
	for (var/line in Lines)

		if (!length(line))				continue
		if (copytext(line,1,2) == "#")	continue

		var/list/List = splittext(line,"+")
		if (!List.len)					continue

		var/rank = ckeyEx(List[1])
		switch(rank)
			if (null,"")		continue
			if ("Removed")	continue				//Reserved

		var/rights = FALSE
		for (var/i=2, i<=List.len, i++)
			switch(ckey(List[i]))
				if ("@","prev")					rights |= previous_rights
				if ("buildmode","build")			rights |= R_BUILDMODE
				if ("admin")						rights |= R_ADMIN
				if ("ban")						rights |= R_BAN
				if ("fun")						rights |= R_FUN
				if ("server")					rights |= R_SERVER
				if ("debug")						rights |= R_DEBUG
				if ("permissions","rights")		rights |= R_PERMISSIONS
				if ("possess")					rights |= R_POSSESS
				if ("stealth")					rights |= R_STEALTH
				if ("rejuv","rejuvinate")		rights |= R_REJUVINATE
				if ("varedit")					rights |= R_VAREDIT
				if ("everything","host","all")	rights |= (R_HOST | R_BUILDMODE | R_ADMIN | R_BAN | R_FUN | R_SERVER | R_DEBUG | R_PERMISSIONS | R_POSSESS | R_STEALTH | R_REJUVINATE | R_VAREDIT | R_SOUNDS | R_SPAWN | R_MOD| R_MENTOR)
				if ("sound","sounds")			rights |= R_SOUNDS
				if ("spawn","create")			rights |= R_SPAWN
				if ("mod")						rights |= R_MOD
				if ("mentor")					rights |= R_MENTOR

		admin_ranks[rank] = rights
		previous_rights = rights

	#ifdef TESTING
	var/msg = "Permission Sets Built:\n"
	for (var/rank in admin_ranks)
		msg += "\t[rank] - [admin_ranks[rank]]\n"
	testing(msg)
	#endif

var/loaded_admins = FALSE

/hook/startup/proc/loadAdmins()
	load_admins()
	return TRUE

/proc/load_admins(var/force = FALSE)
	if (loaded_admins && !force)
		return
	//clear the datums references
	admin_datums.Cut()
	for (var/client/C in admins)
		C.remove_admin_verbs()
		C.holder = null

	admins.Cut()

	load_admin_ranks()

	//load text from file
	var/list/Lines = file2list('code/admins.txt')

	//process each line seperately
	for(var/line in Lines)
		if(!length(line))				continue
		if(copytext(line,1,2) == "#")	continue

		//Split the line at every "-"
		var/list/List = splittext(line, "-")
		if(!List.len)					continue

		//ckey is before the first "-"
		var/ckey = ckey(List[1])
		if(!ckey)						continue

		//rank follows the first "-"
		var/rank = ""
		if(List.len >= 2)
			rank = ckeyEx(List[2])

		//load permissions associated with this rank
		var/rights = admin_ranks[rank]

		//create the admin datum and store it for later use
		var/datum/admins/D = new /datum/admins(rank, rights, ckey)

		//find the client for a ckey if they are connected and associate them with the new admin datum
		D.associate(directory[ckey])



			/* moved association code to client/New(), so it works for clients
			   created at the same time as the world */

	deadminned
	if (!admin_datums)
		/*error("The database query in load_admins() resulted in no admins being added to the list. Reverting to legacy system.")
		log_misc("The database query in load_admins() resulted in no admins being added to the list. Reverting to legacy system.")
		config.admin_legacy_system = TRUE
		load_admins()*/
		loaded_admins = TRUE
		return

	#ifdef TESTING
	var/msg = "Admins Built:\n"
	for (var/ckey in admin_datums)
		var/rank
		var/datum/admins/D = admin_datums[ckey]
		if (D)	rank = D.rank
		msg += "\t[ckey] - [rank]\n"
	testing(msg)
	#endif

	loaded_admins = TRUE

#ifdef TESTING
/client/verb/changerank(newrank in admin_ranks)
	if (holder)
		holder.rank = newrank
		holder.rights = admin_ranks[newrank]
	else
		holder = new /datum/admins(newrank,admin_ranks[newrank],ckey)
	remove_admin_verbs()
	holder.associate(src)

/client/verb/changerights(newrights as num)
	if (holder)
		holder.rights = newrights
	else
		holder = new /datum/admins("testing",newrights,ckey)
	remove_admin_verbs()
	holder.associate(src)

#endif
