package pucrs.agentcontest2017.actions;

import jason.asSemantics.DefaultInternalAction;
import jason.asSemantics.TransitionSystem;
import jason.asSemantics.Unifier;
import jason.asSyntax.NumberTermImpl;
import jason.asSyntax.Term;
import massim.scenario.city.data.Location;
import pucrs.agentcontest2017.env.MapHelper;

public class getLocation extends DefaultInternalAction {

	private static final long serialVersionUID = 432843279827432L;

	@Override
	public Object execute(TransitionSystem ts, Unifier un, Term[] args) throws Exception {
		String locationId = args[0].toString();
		Location location = MapHelper.getLocation(locationId);
		un.unifies(args[1], new NumberTermImpl(location.getLat()));
		un.unifies(args[2], new NumberTermImpl(location.getLon()));
		return true;
	}
}
