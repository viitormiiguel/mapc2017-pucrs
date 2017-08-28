//{include("strategies/job/auction/evaluate-auction.asl",evaluation_auction)}

task_id(0).

@minLon[atomic]
+default::minLon(Lon) : X = Lon + 0.001 & countCenter(I) <- -minLon(Lon); +minLonReal(X); -+countCenter(I+1).
@maxLon[atomic]
+default::maxLon(Lon) : X = Lon - 0.00001 & countCenter(I) <- -maxLon(Lon); +maxLonReal(X); -+countCenter(I+1).
@minLat[atomic]
+default::minLat(Lat) : X = Lat + 0.001 & countCenter(I)  <- -minLat(Lat); +minLatReal(X); -+countCenter(I+1).
@maxLat[atomic]
+default::maxLat(Lat) : X = Lat - 0.00001 & countCenter(I)  <- -maxLat(Lat); +maxLatReal(X); -+countCenter(I+1).

+countCenter(4)
	: minLonReal(MinLon) & maxLonReal(MaxLon) & minLatReal(MinLat) & maxLatReal(MaxLat)
<- 
	-countCenter(4);
	+mapCenter(math.ceil(((MinLat+MaxLat)/2) * 100000) / 100000,math.ceil(((MinLon+MaxLon)/2) * 100000) / 100000);
	.

+default::job(_, _, _, _, _, _) : not initiator::accept_jobs.
@job[atomic]
+default::job(Id, Storage, Reward, Start, End, Items)
	: initiator::free_agents(FreeAgents) & initiator::free_trucks(FreeTrucks) & not .length(FreeTrucks,0) & .length(FreeAgents,FreeAgentsN) & FreeAgentsN >= 2
<- 
	+action::hold_action(Id);
	.print("New job ",Id," deliver to ",Storage," for ",Reward," starting at ",Start," to ",End);
	.print("Items required: ",Items);
	!evaluate_job(Items, End, Storage, Id, Reward);
	.
+default::job(Id, Storage, Reward, Start, End, Items) <- .print("Ignoring job ",Id).

//+!wait_for_step(Step)
//	: default::step(CurrentStep) & (Step <= CurrentStep).
//+!wait_for_step(Step)
//<-
//	.wait({+default::step(Step)});
//	.
//@oldAuction[atomic]
//+default::auction(Id, Storage, Reward, Start, End, Fine, Bid, Time, Items)	
//	: evaluation_auction::bidding(Id,LastBid,_)
//<-	
//	if (Bid == LastBid){
//		.print("I'm winning ",Id);
////		!strategies::free;
//	}
//	else{
//		.print("I'm losing ",Id);
////		.wait({+step(Step)});	
////		.wait({+default::step(Step)});	
////		!strategies::not_free;
//		!strategies::reasoning;
//		!evaluation_auction::analyse_auction_job(Id);
//	}
//	.
//@newAuction[atomic]
//+default::auction(Id, Storage, Reward, Start, End, Fine, Bid, Time, Items)	
////	: not evaluation_auction::bidding(_,_,_)
//	: true
//<-
//	!wait_for_step(Start);
//	.print("############################################################");
////	!strategies::not_free;
//	!strategies::reasoning;
//	.print("New auction job ",Id," deliver to ",Storage," for ",Reward," starting at ",Start," to ",End," has current bid of ",Bid," time for bids ",Time);
//	.print("Items required: ",Items);
//
////	!lAuctionJob::analyse_auction_job(Id, Storage, Reward, Start, End, Fine, Bid, Time, Items);
////	!!separate_tasks(Id, Storage, Items, End, End - Start, Reward, type(auction));
//	!!evaluate_job(Items, End - Start, Storage, Id, Reward);
//	.
//+default::auction(Id, Storage, Reward, Start, End, Fine, Bid, Time, Items) <- .print("Ignoring auction job ",Id).

//+default::mission(Id, Storage, Reward, Start, End, Fine, _, _, Items) : not initiator::accept_jobs <- +mission(Id, Storage, Items, End, Reward, Fine); .print("Ignoring mission ",Id," for now."); .
//@mission[atomic]
//+default::mission(Id, Storage, Reward, Start, End, Fine, _, _, Items)
//	: initiator::free_agents(FreeAgents) & initiator::free_trucks(FreeTrucks) & not .length(FreeTrucks,0) & .length(FreeAgents,FreeAgentsN) & FreeAgentsN >= 2
//<- 
////	+action::hold_action(Id);
//	+mission(Id, Storage, Items, End, Reward, Fine);
//	.print("New mission ",Id," deliver to ",Storage," for ",Reward," starting at ",Start," to ",End," or pay ",Fine);
//	.print("Items required: ",Items);
//	!evaluate_mission(Items, End, Storage, Id, Reward, Fine);
//	.
//+default::mission(Id, Storage, Reward, Start, End, Fine, _, _, Items) <- +mission(Id, Storage, Items, End, Reward, Fine); .print("Ignoring mission ",Id," for now.").
	
+!decompose(Items,ListItems,ListToolsNew,Id)
<-
	?default::decomposeRequirements(Items,[],Bases);
	+bases([],Id);
	for ( .member(Item,Bases) ) {
		?bases(L,Id);
		.concat(L,Item,New);
		-bases(L,Id);
		+bases(New,Id);
	}
	?bases(B,Id);
	-bases(B,Id);
	if (.substring("tool",B)) {
		?default::separateItemTool(B,ListTools,ListItems); 
		?default::removeDuplicateTool(ListTools,ListToolsNew);
	}
	else { ListToolsNew = []; ListItems = B; }
	.

+!evaluate_job(Items, End, Storage, Id, Reward)
	: new::vehicle_job(Role,Speed) & new::workshopList(WList) & default::steps(TotalSteps) & default::step(Step) & initiator::free_agents(FreeAgents) & default::get_roles(FreeAgents,[],Roles) & default::get_tools(Roles,[],AvailableTools) & initiator::eval_shop_route(FarthestShop,RouteShop)
<-
	!decompose(Items,ListItems,ListToolsNew,Id);
	.length(ListToolsNew,NumberOfBuyTool);
	.length(ListItems,NumberOfBuyItem);
	.length(Items,NumberOfAssemble);
	?default::concat_bases(ListItems,[],ListItemsConcat);
	if ( default::check_tools(ListToolsNew,AvailableTools,ResultT) & ResultT == "true" & default::check_buy_list(ListItemsConcat,ResultB) & ResultB == "true" & default::check_multiple_buy(ListItemsConcat,AddSteps) & default::check_price(ListToolsNew,ListItems,0,ResultP) & .print("Estimated cost ",ResultP * 1.1," reward ",Reward) & ResultP * 1.1 < Reward & actions.closest(Role,WList,Storage,ClosestWorkshop) & actions.route(Role,Speed,FarthestShop,ClosestWorkshop,RouteWorkshop) & actions.route(Role,Speed,ClosestWorkshop,Storage,RouteStorage) & Estimate = RouteShop+RouteWorkshop+RouteStorage+NumberOfBuyTool+NumberOfBuyItem+NumberOfAssemble+AddSteps+25 & .print("Estimate ",Estimate+Step," < ",End) & Estimate + Step < End & Step + Estimate < TotalSteps ) {
//		!!separate_tasks(Id, Storage, ListItems, ListToolsNew, Items);
		
		.broadcast(achieve,gTaskAllocation::allocate_job(Id,Storage,Items,[]));
		!gTaskAllocation::allocate_job(Id,Storage,Items,[]);
		-initiator::accept_jobs; // só para forçar somente uma alocação de tarefas
	}
	else { 
		.print("Job ",Id," failed evaluation, ignoring it.");
		!update_eval;
		-action::hold_action(Id);
	}
	.
	
+!evaluate_mission(Items, End, Storage, Id, Reward, Fine)
	: initiator::accept_jobs & not initiator::eval(Id) & default::steps(TotalSteps) & default::step(Step) & initiator::free_agents(FreeAgents) & initiator::free_trucks(FreeTrucks) & not .length(FreeTrucks,0) & .length(FreeAgents,FreeAgentsN) & FreeAgentsN >= 2
<-
	+eval(Id);
//	.print("Evaluating mission ",Id," at step ",Step);
	if ( Step + 40 < TotalSteps & Step + 40 < End ) {
		+action::hold_action(Id);
		!decompose(Items,ListItems,ListToolsNew,Id);
		!!separate_tasks(Id, Storage, ListItems, ListToolsNew, Items);
	}
	else { 
		.print("Mission ",Id," failed evaluation, ignoring it.");
		-action::hold_action(Id);
		-mission(Id, Storage, Items, End, Reward, Fine);
		+failed_mission(Id, End, Fine);
		-eval(Id);
	}
.
+!evaluate_mission(Items, End, Storage, Id, Reward, Fine). //<- .print("Mission is already being evaluated").

@sep_task[atomic]
+!separate_tasks(Id, Storage, ListItems, ListToolsNew, Items)
	: not cnp(_) & new::max_bid_time(Deadline) & initiator::free_trucks(FreeTrucks) & .length(FreeTrucks,NumberOfTrucks) & initiator::free_agents(FreeAgents) & .length(FreeAgents,NumberOfAgents) & NumberOfTrucks > 0 & NumberOfAgents >= 2
<-
//	.print("Tools to be alocated: ",ListToolsNew);
	+cnp(Id);
	+job(Id, Items);
	+number_of_tasks(.length(ListItems)+.length(ListToolsNew)+1,Id);
	?task_id(TaskIdA);
	-+task_id(TaskIdA+1);
//	.print("Creating cnp for assemble task ",Storage," free trucks[",NumberOfTrucks,"]: ",FreeTrucks);
	!!announce(assemble(Storage, Items),Deadline,NumberOfTrucks,Id,TaskIdA,FreeAgents,FreeTrucks);
	for ( .member(item(ItemId,Qty),ListToolsNew) ) {
		?task_id(TaskId);
		-+task_id(TaskId+1);
//		.print("Creating cnp for tool task ",ItemId," free agents[",NumberOfAgents,"]: ",FreeAgents);
		!!announce(tool(ItemId),Deadline,NumberOfAgents,Id,TaskId,FreeAgents,FreeTrucks);
	}
	for ( .member(item(ItemId,Qty),ListItems) ) {
		?task_id(TaskId);
		-+task_id(TaskId+1);
//		.print("Creating cnp for buy task ",ItemId," free agents[",NumberOfAgents,"]: ",FreeAgents);
		!!announce(item(ItemId,Qty),Deadline,NumberOfAgents,Id,TaskId,FreeAgents,FreeTrucks);
	}
	.
+!separate_tasks(Id, Storage, ListItems, ListToolsNew, Items)
	: not cnp(Id) & initiator::free_trucks(FreeTrucks) & .length(FreeTrucks,NumberOfTrucks) & initiator::free_agents(FreeAgents) & .length(FreeAgents,NumberOfAgents) & NumberOfTrucks > 0 & NumberOfAgents >= 2
<-
	.wait(500);
	!!separate_tasks(Id, Storage, ListItems, ListToolsNew, Items);
	.
+!separate_tasks(Id, Storage, ListItems, ListToolsNew, Items) <- -action::hold_action(Id). //<- .print(">>>>>>>>>>>>>>>>>>>>>>> Trying to allocate the same job, or job is no longer viable ",Id).

+!announce(Task,Deadline,NumberOfAgents,JobId,TaskId,FreeAgents,FreeTrucks)
	: true
<- 
	.concat("cnp_board_",TaskId,CNPBoardName);
//	.print("Creating task ",CNPBoardName);
	makeArtifact(CNPBoardName, "cnp.ContractNetBoard", [Task, Deadline, NumberOfAgents]);
	if (.substring("assemble",Task)) { !send_to_free_trucks(FreeTrucks,Task,CNPBoardName,TaskId); }
	else { !send_to_free_agents(FreeAgents,Task,CNPBoardName,TaskId); }
//	.print("Created cnp ",CNPBoardName," for task ",Task);
	getBidsTask(Bids) [artifact_name(CNPBoardName)];
	if (.length(Bids) \== 0) {		
//		.print("Got bids (",.length(Bids),") for task #",Qty," ",ItemId," Bids: ",Bids);
		+bids(Task,Bids,JobId);
	}
	else {
		.print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> No bids ",JobId);
		?metrics::noBids(NoBids);
		-+metrics::noBids(NoBids+1);
		+bids(Task,[bid(99999,99999,99999,Task,TaskId)],JobId);
	}
	remove[artifact_name(CNPBoardName)];
	.
	
@sendfreetrucks[atomic]
+!send_to_free_trucks(FreeTrucks,Task,CNPBoardName,TaskId)
<-
	for ( .member(Agent,FreeTrucks) ) {
		.send(Agent,tell,task(Task,CNPBoardName,TaskId));
	}
	.
@sendfreeagents[atomic]
+!send_to_free_agents(FreeAgents,Task,CNPBoardName,TaskId)
<-
	for ( .member(Agent,FreeAgents) ) {
		.send(Agent,tell,task(Task,CNPBoardName,TaskId));
	}
	.
	
@selectBids[atomic]
+bids(_,_,JobId)
	: .count(initiator::bids(_,_,JobId),NumberOfBids) & number_of_tasks(NumberOfTasks,JobId) & NumberOfBids == NumberOfTasks & .my_name(Me)
<-
//	.print("Received all bids ",JobId);
	-number_of_tasks(NumberOfTasks,JobId);
	for ( initiator::bids(assemble(StorageId,_),Bids,JobId) ) {
		if ( not initiator::impossible_task(JobId) ) {
			-bids(assemble(StorageId,_),Bids,JobId);
			?default::select_bid_assemble(Bids,bid(99999,99999),bid(Agent,Distance));
			if (Distance \== 99999) {
//				.print("Awarding assemble of ",JobId," to ",Agent);
				?initiator::job(JobId, Items);
				+awarded_assemble(Agent,Items,StorageId,[],JobId);
			}
			else { +initiator::impossible_task(JobId); .print("Unable to allocate assemble to deliver at ",StorageId); }
		}
	}
	if ( not initiator::impossible_task(JobId) ) {
		for ( initiator::bids(tool(ItemId),Bids,JobId) ) {
			if ( not initiator::impossible_task(JobId) ) {
				-bids(tool(ItemId),Bids,JobId);
				?default::select_bid_tool(Bids,bid(99999,99999,99999),bid(Agent,Distance,Shop));
				if (Distance \== 99999) {
					getLoad(Agent,Load);
					?default::item(ItemId,Volume,_,_);
			    	addLoad(Agent,Load-Volume);
		//	    	.print("Awarding ",ItemId," to ",Agent," at",Shop);
					if (not initiator::awarded(Agent,_,_,_,_)) {
						+awarded(Agent,Shop,[tool(ItemId)],JobId,1);
					}
					else {
						?awarded(Agent,_,List,JobId,TaskCount);
			    		-awarded(Agent,_,List,JobId,TaskCount);
			    		.concat(List,[tool(ItemId)],NewList);
			    		+awarded(Agent,Shop,NewList,JobId,TaskCount+1);
					}
				}
				else { +initiator::impossible_task(JobId); .print("Unable to allocate tool ",ItemId); }
			}
		}
		for ( initiator::bids(item(ItemId,Qty),Bids,JobId) ) {
			if ( not initiator::impossible_task(JobId) ) {
				-bids(item(ItemId,Qty),Bids,JobId);
				?default::select_bid(Bids,bid(99999,99999,99999),bid(Agent,Distance,Shop));
				if (Distance \== 99999) {
					getLoad(Agent,Load);
					?default::item(ItemId,Volume,_,_);
			    	addLoad(Agent,Load-Volume*Qty);
		//	    	.print("Awarding #",Qty," of ",ItemId," to ",Agent," at",Shop);
					if (not initiator::awarded(Agent,_,_,_,_)) {
						+awarded(Agent,Shop,[item(ItemId,Qty)],JobId,1);
					}
					else {
						?awarded(Agent,_,List,JobId,TaskCount);
			    		-awarded(Agent,_,List,JobId,TaskCount);
			    		.concat(List,[item(ItemId,Qty)],NewList);
			    		+awarded(Agent,Shop,NewList,JobId,TaskCount+1);
					}
				}
				else { +initiator::impossible_task(JobId); .print("Unable to allocate #",Qty," of ",ItemId); }
			}
		}
	}
	if (not initiator::impossible_task(JobId)) {
		?default::joined(org,OrgId);
//		.print("Creating scheme for ",JobId);
		!create_scheme(JobId, st, SchArtId,OrgId);
//		debug(inspector_gui(on))[artifact_id(SchArtId)];
		?awarded_assemble(AgentA,Items,Storage,AssTaskList,JobId);
		-awarded_assemble(AgentA,Items,Storage,AssTaskList,JobId);
		?initiator::free_agents(FreeAgentsA);
		?initiator::free_trucks(FreeTrucksA);
		.delete(AgentA,FreeTrucksA,FreeTrucksNewA);
		-+initiator::free_trucks(FreeTrucksNewA);
		.delete(AgentA,FreeAgentsA,FreeAgentsNewA);
		-+initiator::free_agents(FreeAgentsNewA);
//		.print("Removing ",AgentA," from free lists.");
		for ( initiator::awarded(Agent,Shop,List,JobId,TaskCount) ) {
//			.print("Removing ",Agent," from free lists.");
			?initiator::free_agents(FreeAgents);
			.delete(Agent,FreeAgents,FreeAgentsNew);
			-+initiator::free_agents(FreeAgentsNew);
			?initiator::free_trucks(FreeTrucks);
			if (.member(Agent,FreeTrucks)) {
				.delete(Agent,FreeTrucks,FreeTrucksNew);
				-+initiator::free_trucks(FreeTrucksNew);
			}
	    	.send(Agent,tell,winner(List,assist(Storage,AgentA,JobId)));
			-awarded(Agent,Shop,List,JobId,TaskCount);	
		}
		.send(AgentA,tell,winner(Items,assemble(Storage,JobId,AssTaskList)));
		if (initiator::mission(JobId, _, _, _, _, _)) { -initiator::mission(JobId, _, _, _, _, _); -eval(JobId); }
		resetLoads;
		-cnp(JobId);
		
//		.wait(50);
//		!evaluation_auction::analyse_auction_job(JobId);
	}
	else {
		resetLoads;
		-impossible_task(JobId);
		-cnp(JobId);
		-job(JobId, _);
		-awarded_assemble(_,_,_,_,JobId);
		-eval(JobId);
		.abolish(initiator::bids(_,_,JobId));
		.abolish(initiator::awarded(_,_,_,JobId,_));
		.print("Impossible job ",JobId,", aborting it.");
	}
	-action::hold_action(JobId);
//	.print("Task allocation is done ",JobId);
	.
+!create_scheme(JobId, st, SchArtId,OrgId) <- org::createScheme(JobId, st, SchArtId)[wid(OrgId)].
-!create_scheme(JobId, st, SchArtId,OrgId) 
<-
	resetLoads;
	-impossible_task(JobId);
	-cnp(JobId);
	-job(JobId, _);
	-awarded_assemble(_,_,_,_,JobId);
	-eval(JobId);
	.abolish(initiator::bids(_,_,JobId));
	.abolish(initiator::awarded(_,_,_,JobId,_));
	.print("Bug with create scheme for ",JobId,", detected, aborting it.");
	-action::hold_action(JobId);
	.

@addAgentFree[atomic]
+!add_agent_to_free[source(Agent)]
	: initiator::free_agents(FreeAgents)
<-
	-+initiator::free_agents([Agent|FreeAgents]);
	if (initiator::accept_jobs) {
		for (initiator::mission(Id, Storage, Items, End, Reward, Fine)) {
			!evaluate_mission(Items, End, Storage, Id, Reward, Fine);
		}
	}
	.
@addTruckFree[atomic]
+!add_truck_to_free[source(Agent)]
	: initiator::free_agents(FreeAgents) & initiator::free_trucks(FreeTrucks)
<-
	-+initiator::free_agents([Agent|FreeAgents]);
	-+initiator::free_trucks([Agent|FreeTrucks]);
	if (initiator::accept_jobs) {
		for (initiator::mission(Id, Storage, Items, End, Reward, Fine)) {
			!evaluate_mission(Items, End, Storage, Id, Reward, Fine);
		}
	}
	.
@addMeFree[atomic]
+!add_myself_to_free
	: initiator::free_agents(FreeAgents) & .my_name(Me)
<-
	-+initiator::free_agents([Me|FreeAgents]);
	if (initiator::accept_jobs) {
		for (initiator::mission(Id, Storage, Items, End, Reward, Fine)) {
			!evaluate_mission(Items, End, Storage, Id, Reward, Fine);
		}
	}
	.
	
@jobFinished[atomic]	
+!job_finished(JobId) 
<- 
	-initiator::job(JobId, _);
	?metrics::completedJobs(C);
	-+metrics::completedJobs(C+1);
//	?estimate(JobId,Start,Estimate);
//	?default::step(Step);
//	.print("Finished job ",JobId," at step ",Step," estimated to end in ",Start+Estimate);
//	-estimate(JobId,Start,Estimate);
	.

@missionFinished[atomic]	
+!mission_finished(JobId) 
<- 
	-initiator::job(JobId, _);
	?metrics::completedMissions(C);
	-+metrics::completedMissions(C+1);
//	?estimate(JobId,Start,Estimate);
//	?default::step(Step);
//	.print("Finished job ",JobId," at step ",Step," estimated to end in ",Start+Estimate);
//	-estimate(JobId,Start,Estimate);
	.
	
@upateJobEval[atomic]
+!update_eval
	: metrics::failedEvalJobs(C)
<-
	-+metrics::failedEvalJobs(C+1);
.

@upateJobFail[atomic]
+!update_job_failed
	: metrics::failedJobs(C)
<-
	-+metrics::failedJobs(C+1);
.

@upateMissionFail[atomic]
+!update_mission_failed(FineNew)
	: metrics::failedMissions(C) & metrics::finePaid(OldFine) 
<-
	-+metrics::failedMissions(C+1);
	-+metrics::finePaid(OldFine+FineNew);
.

+default::step(End)
	: initiator::mission(Id, _, _, End, _, Fine) | initiator::failed_mission(Id, End, Fine)
<-
	.print("!!!!!!!!!!!!!!!!! Mission ",Id," failed: deadline.");
	-initiator::mission(Id, _, _, End, _, Fine);
	-initiator::failed_mission(Id, End, Fine);
	!update_mission_failed(Fine);
	.
// debugging
+default::step(998)
	: default::money(Money)
<-	
	-+metrics::money(Money);
.