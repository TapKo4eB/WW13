var/list/flooring_cache = list()

/turf/floor/update_icon(var/update_neighbors)

/*	if (lava)
		return*/

	if (flooring)
		// Set initial icon and strings.
		name = flooring.name
		desc = flooring.desc
		icon = flooring.icon
		if (!isnull(set_update_icon) && istext(set_update_icon))
			icon_state = set_update_icon
		else if (flooring_override)
			icon_state = flooring_override
		else
			if (overrided_icon_state)
				icon_state = overrided_icon_state
				flooring_override = icon_state
			else
				icon_state = flooring.icon_base
				if (flooring.has_base_range)
					icon_state = "[icon_state][rand(0,flooring.has_base_range)]"
					flooring_override = icon_state


		// Apply edges, corners, and inner corners.
		overlays.Cut()
		var/has_border = FALSE
		if (flooring.flags & SMOOTH_ONLY_WITH_ITSELF) // for carpets and stuff like that
			if (isnull(set_update_icon) && (flooring.flags & TURF_HAS_EDGES))
				for(var/step_dir in cardinal)
					var/turf/floor/T = get_step(src, step_dir)
					if (!istype(T) || !T.flooring || T.flooring.name != flooring.name)
						has_border |= step_dir
						overlays |= get_flooring_overlay("[flooring.icon_base]-edge-[step_dir]", "[flooring.icon_base]_edges", step_dir)
				if ((flooring.flags & TURF_USE0ICON) && has_border)
					icon_state = flooring.icon_base+"0"

				// There has to be a concise numerical way to do this but I am too noob.
				if ((has_border & NORTH) && (has_border & EAST))
					overlays |= get_flooring_overlay("[flooring.icon_base]-edge-[NORTHEAST]", "[flooring.icon_base]_edges", NORTHEAST)
				if ((has_border & NORTH) && (has_border & WEST))
					overlays |= get_flooring_overlay("[flooring.icon_base]-edge-[NORTHWEST]", "[flooring.icon_base]_edges", NORTHWEST)
				if ((has_border & SOUTH) && (has_border & EAST))
					overlays |= get_flooring_overlay("[flooring.icon_base]-edge-[SOUTHEAST]", "[flooring.icon_base]_edges", SOUTHEAST)
				if ((has_border & SOUTH) && (has_border & WEST))
					overlays |= get_flooring_overlay("[flooring.icon_base]-edge-[SOUTHWEST]", "[flooring.icon_base]_edges", SOUTHWEST)

				if (flooring.flags & TURF_HAS_CORNERS)
					// As above re: concise numerical way to do this.
					if (!(has_border & NORTH))
						if (!(has_border & EAST))
							var/turf/floor/T = get_step(src, NORTHEAST)
							if (!istype(T) || !T.flooring || T.flooring.name != flooring.name)
								overlays |= get_flooring_overlay("[flooring.icon_base]-corner-[NORTHEAST]", "[flooring.icon_base]_corners", NORTHEAST)
						if (!(has_border & WEST))
							var/turf/floor/T = get_step(src, NORTHWEST)
							if (!istype(T) || !T.flooring || T.flooring.name != flooring.name)
								overlays |= get_flooring_overlay("[flooring.icon_base]-corner-[NORTHWEST]", "[flooring.icon_base]_corners", NORTHWEST)
					if (!(has_border & SOUTH))
						if (!(has_border & EAST))
							var/turf/floor/T = get_step(src, SOUTHEAST)
							if (!istype(T) || !T.flooring || T.flooring.name != flooring.name)
								overlays |= get_flooring_overlay("[flooring.icon_base]-corner-[SOUTHEAST]", "[flooring.icon_base]_corners", SOUTHEAST)
						if (!(has_border & WEST))
							var/turf/floor/T = get_step(src, SOUTHWEST)
							if (!istype(T) || !T.flooring || T.flooring.name != flooring.name)
								overlays |= get_flooring_overlay("[flooring.icon_base]-corner-[SOUTHWEST]", "[flooring.icon_base]_corners", SOUTHWEST)

		else
			if (isnull(set_update_icon) && (flooring.flags & TURF_HAS_EDGES))
				for(var/step_dir in cardinal)
					var/turf/T = get_step(src, step_dir)
					if (istype(T, /turf/open) || istype(T, /turf/space))
						has_border |= step_dir
						overlays |= get_flooring_overlay("[flooring.icon_base]-edge-[step_dir]", "[flooring.icon_base]_edges", step_dir)
				if ((flooring.flags & TURF_USE0ICON) && has_border)
					icon_state = flooring.icon_base+"0"

				// There has to be a concise numerical way to do this but I am too noob.
				if ((has_border & NORTH) && (has_border & EAST))
					overlays |= get_flooring_overlay("[flooring.icon_base]-edge-[NORTHEAST]", "[flooring.icon_base]_edges", NORTHEAST)
				if ((has_border & NORTH) && (has_border & WEST))
					overlays |= get_flooring_overlay("[flooring.icon_base]-edge-[NORTHWEST]", "[flooring.icon_base]_edges", NORTHWEST)
				if ((has_border & SOUTH) && (has_border & EAST))
					overlays |= get_flooring_overlay("[flooring.icon_base]-edge-[SOUTHEAST]", "[flooring.icon_base]_edges", SOUTHEAST)
				if ((has_border & SOUTH) && (has_border & WEST))
					overlays |= get_flooring_overlay("[flooring.icon_base]-edge-[SOUTHWEST]", "[flooring.icon_base]_edges", SOUTHWEST)

				if (flooring.flags & TURF_HAS_CORNERS)
					// As above re: concise numerical way to do this.
					if (!(has_border & NORTH))
						if (!(has_border & EAST))
							var/turf/floor/T = get_step(src, NORTHEAST)
							if (istype(T, /turf/open) || istype(T, /turf/space))
								overlays |= get_flooring_overlay("[flooring.icon_base]-corner-[NORTHEAST]", "[flooring.icon_base]_corners", NORTHEAST)
						if (!(has_border & WEST))
							var/turf/floor/T = get_step(src, NORTHWEST)
							if (istype(T, /turf/open) || istype(T, /turf/space))
								overlays |= get_flooring_overlay("[flooring.icon_base]-corner-[NORTHWEST]", "[flooring.icon_base]_corners", NORTHWEST)
					if (!(has_border & SOUTH))
						if (!(has_border & EAST))
							var/turf/floor/T = get_step(src, SOUTHEAST)
							if (istype(T, /turf/open) || istype(T, /turf/space))
								overlays |= get_flooring_overlay("[flooring.icon_base]-corner-[SOUTHEAST]", "[flooring.icon_base]_corners", SOUTHEAST)
						if (!(has_border & WEST))
							var/turf/floor/T = get_step(src, SOUTHWEST)
							if (istype(T, /turf/open) || istype(T, /turf/space))
								overlays |= get_flooring_overlay("[flooring.icon_base]-corner-[SOUTHWEST]", "[flooring.icon_base]_corners", SOUTHWEST)

	if (decals && decals.len)
		overlays |= decals

	if (is_plating() && !(isnull(broken) && isnull(burnt))) //temp, todo
		icon = 'icons/turf/flooring/plating.dmi'
		icon_state = "dmg[rand(1,4)]"
	else if (flooring)
		if (!isnull(broken) && (flooring.flags & TURF_CAN_BREAK))
			overlays |= get_flooring_overlay("[flooring.icon_base]-broken-[broken]", "broken[broken]")
		if (!isnull(burnt) && (flooring.flags & TURF_CAN_BURN))
			overlays |= get_flooring_overlay("[flooring.icon_base]-burned-[burnt]", "burned[burnt]")

	if (update_neighbors)
		for(var/turf/floor/F in range(src, TRUE))
			if (F == src)
				continue
			F.update_icon()

/turf/floor/proc/get_flooring_overlay(var/cache_key, var/icon_base, var/icon_dir = FALSE)
	if (!flooring_cache[cache_key])
		var/image/I = image(icon = flooring.icon, icon_state = icon_base, dir = icon_dir)
		I.layer = layer
		flooring_cache[cache_key] = I
	return flooring_cache[cache_key]