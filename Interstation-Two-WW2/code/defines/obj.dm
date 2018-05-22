/obj/structure/signpost
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "signpost"
	anchored = TRUE
	density = TRUE

	attackby(obj/item/weapon/W as obj, mob/user as mob)
		return attack_hand(user)

	attack_hand(mob/user as mob)
		switch(alert("Travel back to ss13?",,"Yes","No"))
			if ("Yes")
				if (user.z != z)	return
				user.loc.loc.Exited(user)
				user.loc = pick(latejoin)
			if ("No")
				return

/obj/effect/mark
		var/mark = ""
		icon = 'icons/misc/mark.dmi'
		icon_state = "blank"
		anchored = TRUE
		layer = 99
		mouse_opacity = FALSE
	//	unacidable = TRUE//Just to be sure.

/obj/effect/beam
	name = "beam"
	density = FALSE
//	unacidable = TRUE//Just to be sure.
	var/def_zone
	flags = PROXMOVE
	pass_flags = PASSTABLE


/obj/effect/begin
	name = "begin"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "begin"
	anchored = 1.0
//	unacidable = TRUE

/*
 * This item is completely unused, but removing it will break something in R&D and Radio code causing PDA and Ninja code to fail on compile
 */

/var/list/acting_rank_prefixes = list("acting", "temporary", "interim", "provisional")

/proc/make_list_rank(rank)
	for(var/prefix in acting_rank_prefixes)
		if (findtext(rank, "[prefix] ", TRUE, 2+length(prefix)))
			return copytext(rank, 2+length(prefix))
	return rank


/*
We can't just insert in HTML into the nanoUI so we need the raw data to play with.
Instead of creating this list over and over when someone leaves their PDA open to the page
we'll only update it when it changes.  The PDA_Manifest global list is zeroed out upon any change
using /datum/datacore/proc/manifest_inject( ), or manifest_insert( )
*/

/*
var/global/list/PDA_Manifest = list()
var/global/ManifestJSON

/datum/datacore/proc/get_manifest_json()
	if (PDA_Manifest.len)
		return
	var/heads[0]
	var/sec[0]
	var/eng[0]
	var/med[0]
	var/sci[0]
	var/car[0]
	var/civ[0]
	var/bot[0]
	var/misc[0]
	for(var/datum/data/record/t in data_core.general)
		var/name = sanitize(t.fields["name"])
		var/rank = sanitize(t.fields["rank"])
		var/real_rank = make_list_rank(t.fields["real_rank"])

		var/isactive = t.fields["p_stat"]
		var/department = FALSE
		var/depthead = FALSE 			// Department Heads will be placed at the top of their lists.
		if (real_rank in command_positions)
			heads[++heads.len] = list("name" = name, "rank" = rank, "active" = isactive)
			department = TRUE
			depthead = TRUE
			if (rank=="Captain" && heads.len != TRUE)
				heads.Swap(1,heads.len)

		if (real_rank in security_positions)
			sec[++sec.len] = list("name" = name, "rank" = rank, "active" = isactive)
			department = TRUE
			if (depthead && sec.len != TRUE)
				sec.Swap(1,sec.len)

		if (real_rank in engineering_positions)
			eng[++eng.len] = list("name" = name, "rank" = rank, "active" = isactive)
			department = TRUE
			if (depthead && eng.len != TRUE)
				eng.Swap(1,eng.len)

		if (real_rank in medical_positions)
			med[++med.len] = list("name" = name, "rank" = rank, "active" = isactive)
			department = TRUE
			if (depthead && med.len != TRUE)
				med.Swap(1,med.len)

		if (real_rank in science_positions)
			sci[++sci.len] = list("name" = name, "rank" = rank, "active" = isactive)
			department = TRUE
			if (depthead && sci.len != TRUE)
				sci.Swap(1,sci.len)

		if (real_rank in cargo_positions)
			car[++car.len] = list("name" = name, "rank" = rank, "active" = isactive)
			department = TRUE
			if (depthead && car.len != TRUE)
				car.Swap(1,car.len)

		if (real_rank in civilian_positions)
			civ[++civ.len] = list("name" = name, "rank" = rank, "active" = isactive)
			department = TRUE
			if (depthead && civ.len != TRUE)
				civ.Swap(1,civ.len)

		if (real_rank in nonhuman_positions)
			bot[++bot.len] = list("name" = name, "rank" = rank, "active" = isactive)
			department = TRUE

		if (!department && !(name in heads))
			misc[++misc.len] = list("name" = name, "rank" = rank, "active" = isactive)


	PDA_Manifest = list(\
		"heads" = heads,\
		"sec" = sec,\
		"eng" = eng,\
		"med" = med,\
		"sci" = sci,\
		"car" = car,\
		"civ" = civ,\
		"bot" = bot,\
		"misc" = misc\
		)
	ManifestJSON = json_encode(PDA_Manifest)
	return

(/


*/
/*
/obj/effect/laser
	name = "laser"
	desc = "IT BURNS!!!"
	icon = 'icons/obj/projectiles.dmi'
	var/damage = 0.0
	var/range = 10.0
*/

/obj/effect/list_container
	name = "list container"

/obj/effect/list_container/mobl
	name = "mobl"
	var/master = null

	var/list/container = list(  )

/obj/effect/projection
	name = "Projection"
	desc = "This looks like a projection of something."
	anchored = 1.0


/obj/effect/shut_controller
	name = "shut controller"
	var/moving = null
	var/list/parts = list(  )

/obj/structure/showcase
	name = "Showcase"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "showcase_1"
	desc = "A stand with the empty body of a cyborg bolted to it."
	density = TRUE
	anchored = TRUE
//	unacidable = TRUE//temporary until I decide whether the borg can be removed. -veyveyr

/obj/item/mouse_drag_pointer = MOUSE_ACTIVE_POINTER

/obj/item/weapon/beach_ball
	icon = 'icons/misc/beach.dmi'
	icon_state = "ball"
	name = "beach ball"
	item_state = "beachball"
	density = FALSE
	anchored = FALSE
	w_class = 4
	force = 0.0
	throwforce = 0.0
	throw_speed = TRUE
	throw_range = 20
	flags = CONDUCT

	afterattack(atom/target as mob|obj|turf|area, mob/user as mob)
		user.drop_item()
		throw_at(target, throw_range, throw_speed, user)

/obj/effect/stop
	var/victim = null
	icon_state = "empty"
	name = "Geas"
	desc = "You can't resist."
	// name = ""

/obj/effect/spawner
	name = "object spawner"
