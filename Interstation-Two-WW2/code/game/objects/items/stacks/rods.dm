/obj/item/stack/rods
	name = "metal rod"
	desc = "Some rods. Can be used for building, or something."
	singular_name = "metal rod"
	icon_state = "rods"
	flags = CONDUCT
	w_class = 3.0
	force = WEAPON_FORCE_PAINFUL
	throwforce = WEAPON_FORCE_PAINFUL
	throw_speed = 5
	throw_range = 20
	matter = list(DEFAULT_WALL_MATERIAL = 1875)
	max_amount = 60
	attack_verb = list("hit", "bludgeoned", "whacked")

/obj/item/stack/rods/cyborg
	name = "metal rod synthesizer"
	desc = "A device that makes metal rods."
	gender = NEUTER
	matter = null
	uses_charge = TRUE
	charge_costs = list(500)
	stacktype = /obj/item/stack/rods

/obj/item/stack/rods/attackby(obj/item/W as obj, mob/user as mob)
	..()
	if (istype(W, /obj/item/weapon/weldingtool))
		var/obj/item/weapon/weldingtool/WT = W

		if (get_amount() < 2)
			user << "<span class='warning'>You need at least two rods to do this.</span>"
			return

		if (WT.remove_fuel(0,user))
			var/obj/item/stack/material/steel/new_item = new(usr.loc)
			new_item.add_to_stacks(usr)
			for (var/mob/M in viewers(src))
				M.show_message("<span class='notice'>[src] is shaped into metal by [user.name] with the weldingtool.</span>", 3, "<span class='notice'>You hear welding.</span>", 2)
			var/obj/item/stack/rods/R = src
			src = null
			var/replace = (user.get_inactive_hand()==R)
			R.use(2)
			if (!R && replace)
				user.put_in_hands(new_item)
		return
	..()


/obj/item/stack/rods/attack_self(mob/user as mob)
	add_fingerprint(user)

	if (!istype(user.loc,/turf)) return FALSE

	if (locate(/obj/structure/grille, usr.loc))
		for(var/obj/structure/grille/G in usr.loc)
			if (G.destroyed)
				G.health = 10
				G.density = TRUE
				G.destroyed = FALSE
				G.icon_state = "grille"
				use(1)
			else
				return TRUE

	else if (!in_use)
		if (get_amount() < 2)
			user << "<span class='warning'>You need at least two rods to do this.</span>"
			return
		usr << "<span class='notice'>Assembling grille...</span>"
		in_use = TRUE
		if (!do_after(usr, 10))
			in_use = FALSE
			return
		var/obj/structure/grille/F = new /obj/structure/grille/ ( usr.loc )
		usr << "<span class='notice'>You assemble a grille</span>"
		in_use = FALSE
		F.add_fingerprint(usr)
		use(2)
	return
