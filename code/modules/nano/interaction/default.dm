/var/global/datum/topic_state/default/default_state = new()

/datum/topic_state/default/href_list(var/mob/user)
	return list()

/datum/topic_state/default/can_use_topic(var/src_object, var/mob/user)
	return user.default_can_use_topic(src_object)

/mob/proc/default_can_use_topic(var/src_object)
	return STATUS_CLOSE // By default no mob can do anything with NanoUI

/mob/dead/observer/default_can_use_topic()
	if(check_rights(R_ADMIN, 0, src))
		return STATUS_INTERACTIVE				// Admins are more equal
	return STATUS_UPDATE						// Ghosts can view updates

/mob/living/silicon/pai/default_can_use_topic(var/src_object)
	if(src_object == src && !stat)
		return STATUS_INTERACTIVE
	else
		return ..()

/mob/living/silicon/robot/default_can_use_topic(var/src_object)
	. = shared_nano_interaction()
	if(. <= STATUS_DISABLED)
		return

	// robots can interact with things they can see within their view range
	if((src_object in view(src)) && get_dist(src_object, src) <= src.client.view)
		return STATUS_INTERACTIVE	// interactive (green visibility)
	return STATUS_DISABLED			// no updates, completely disabled (red visibility)

/mob/living/silicon/robot/syndicate/default_can_use_topic(var/src_object)
	. = ..()
	if(. != STATUS_INTERACTIVE)
		return

	if(z in config.admin_levels)						// Syndicate borgs can interact with everything on the admin level
		return STATUS_INTERACTIVE
	if(istype(get_area(src), /area/syndicate_station))	// If elsewhere, they can interact with everything on the syndicate shuttle
		return STATUS_INTERACTIVE
	if(istype(src_object, /obj/machinery))				// Otherwise they can only interact with emagged machinery
		var/obj/machinery/Machine = src_object
		if(Machine.emagged)
			return STATUS_INTERACTIVE
	return STATUS_UPDATE

/mob/living/silicon/ai/default_can_use_topic(var/src_object)
	. = shared_nano_interaction()
	if(. != STATUS_INTERACTIVE)
		return

	// Prevents the AI from using Topic on admin levels (by for example viewing through the court/thunderdome cameras)
	// unless it's on the same level as the object it's interacting with.
	var/turf/T = get_turf(src_object)
	if(!T || !(z == T.z || (T.z in config.player_levels)))
		return STATUS_CLOSE

	// If an object is in view then we can interact with it
	if(src_object in view(client.view, src))
		return STATUS_INTERACTIVE

	// If we're installed in a chassi, rather than transfered to an inteliCard or other container, then check if we have camera view
	if(is_in_chassis())
		//stop AIs from leaving windows open and using then after they lose vision
		if(cameranet && !cameranet.checkTurfVis(get_turf(src_object)))
			return STATUS_CLOSE
		return STATUS_INTERACTIVE
	else if(get_dist(src_object, src) <= client.view)	// View does not return what one would expect while installed in an inteliCard
		return STATUS_INTERACTIVE

	return STATUS_CLOSE

//Some atoms such as vehicles might have special rules for how mobs inside them interact with NanoUI.
/atom/proc/contents_nano_distance(var/src_object, var/mob/living/user)
	return user.shared_living_nano_distance(src_object)

/mob/living/proc/shared_living_nano_distance(var/atom/movable/src_object)
	if (!(src_object in view(4, src))) 	// If the src object is not in visable, disable updates
		return STATUS_CLOSE

	var/dist = get_dist(src_object, src)
	if (dist <= 1)
		return STATUS_INTERACTIVE	// interactive (green visibility)
	else if (dist <= 2)
		return STATUS_UPDATE 		// update only (orange visibility)
	else if (dist <= 4)
		return STATUS_DISABLED 		// no updates, completely disabled (red visibility)
	return STATUS_CLOSE

/mob/living/default_can_use_topic(var/src_object)
	. = shared_nano_interaction(src_object)
	if(. != STATUS_CLOSE)
		if(loc)
			. = min(., loc.contents_nano_distance(src_object, src))
	if(STATUS_INTERACTIVE)
		return STATUS_UPDATE

/mob/living/carbon/human/default_can_use_topic(var/src_object)
	. = shared_nano_interaction(src_object)
	if(. != STATUS_CLOSE)
		. = min(., shared_living_nano_distance(src_object))
		if(. == STATUS_UPDATE && (TK in mutations))	// If we have telekinesis and remain close enough, allow interaction.
			return STATUS_INTERACTIVE
