/obj/effect/proc_holder/changeling/swap_form
	name = "Swap Forms"
	desc = "We force ourselves into the body of another form, pushing their consciousness into the form we left behind."
	helptext = "We will bring all our abilities with us, but we will lose our old form DNA in exchange for the new one. The process will seem suspicious to any observers."
	chemical_cost = 40
	dna_cost = 1
	req_human = 1 //Monkeys can't grab

/obj/effect/proc_holder/changeling/swap_form/can_sting(var/mob/living/carbon/user)
	if(!..())
		return
	var/obj/item/weapon/grab/G = user.get_active_hand()
	if(!istype(G) || (G.state < GRAB_AGGRESSIVE))
		user << "<span class='warning'>We must have an aggressive grab on creature in our active hand to do this!</span>"
		return
	var/mob/living/carbon/human/target = G.affecting
	if((NOCLONE || SKELETON || HUSK) in target.mutations)
		user << "<span class='warning'>DNA of [target] is ruined beyond usability!</span>"
		return
	if(!istype(target) || issmall(target) || target.species.flags & NO_DNA_RAD || target.species.flags & NO_SCAN || target.species.flags & NO_BLOOD)
		user << "<span class='warning'>[target] is not compatible with this ability.</span>"
		return
	return 1


/obj/effect/proc_holder/changeling/swap_form/sting_action(var/mob/living/carbon/user)
	var/obj/item/weapon/grab/G = user.get_active_hand()
	var/mob/living/carbon/human/target = G.affecting
	var/datum/changeling/changeling = user.mind.changeling

	user << "<span class='notice'>We tighen our grip. We must hold still....</span>"
	target.do_jitter_animation(500)
	user.do_jitter_animation(500)

	if(!do_mob(user,target,20))
		user << "<span class='warning'>The body swap has been interrupted!</span>"
		return

	target << "<span class='userdanger'>[user] tightens their grip as a painful sensation invades your body.</span>"

	if(!changeling.has_dna(target.dna))
		changeling.absorb_dna(target, user)
	changeling.protected_dna -= user.dna
	changeling.absorbed_dna -= user.dna

	var/mob/dead/observer/ghost = target.ghostize(0)
	user.mind.transfer_to(target)
	if(ghost && ghost.mind)
		ghost.mind.transfer_to(user)
		user.key = ghost.key

	user.Paralyse(2)
	target << "<span class='warning'>Our genes cry out as we swap our [user] form for [target].</span>"