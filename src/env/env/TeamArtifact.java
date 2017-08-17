package env;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.logging.Logger;

import cartago.*;


public class TeamArtifact extends Artifact {

	private static Logger logger = Logger.getLogger(TeamArtifact.class.getName());
	private static Map<String, Integer> shopItemsQty = new HashMap<String, Integer>();
	private static Map<String, Integer> itemsQty = new HashMap<String, Integer>();
	private static Map<String, Integer> itemsPrice = new HashMap<String, Integer>();
	private static Map<String, String> agentNames = new HashMap<String, String>();
	private static Map<String, String> agentRoles = new HashMap<String, String>();
	private static Map<String, Integer> loads = new HashMap<String, Integer>();
	private Map<String, ArrayList<String>> availableItems = new HashMap<String,ArrayList<String>>();
	
	void init(){
		logger.info("Team Artifact has been created!");
	}
	
	@OPERATION void createAvailableList(String storage){
		availableItems.put(storage, new ArrayList<String>());
		String[] itemsAux = availableItems.get(storage).toArray(new String[availableItems.get(storage).size()]);
		this.defineObsProperty("available_items", storage, itemsAux);
	}
	
	@OPERATION void addAvailableItem(String storage, String item, int qty){
		if (availableItems.get(storage).toString().contains(item)) {
			for (String s: availableItems.get(storage)) {
				if (s.contains(item)) {
					int ind = availableItems.get(storage).indexOf(s);
					int newqty = qty + Integer.parseInt(""+s.subSequence(s.indexOf(",")+1, s.length()-1));
					availableItems.get(storage).set(ind,"item("+item+","+newqty+")");
//					logger.info("@@@@@ List "+availableItems.get(storage)+" already contains "+item+" index "+availableItems.get(storage).indexOf(s));
				}
			}
		}
		else { availableItems.get(storage).add("item("+item+","+qty+")"); }
		String[] itemsAux = availableItems.get(storage).toArray(new String[availableItems.get(storage).size()]);
//		logger.info("@@@@@@@@@ Adding available item "+item+" to storage "+storage+". Result = "+Arrays.toString(itemsAux)+". Size = "+availableItems.get(storage).size());
		this.removeObsPropertyByTemplate("available_items", storage, null);
		this.defineObsProperty("available_items", storage, itemsAux);
	}
	
	@OPERATION void removeAvailableItem(String storage, String item, int qty){
		int remove = -1;
		if (availableItems.get(storage).toString().contains(item)) {
			for (String s: availableItems.get(storage)) {
				if (s.contains(item)) {
					int ind = availableItems.get(storage).indexOf(s);
					int newqty = Integer.parseInt(""+s.subSequence(s.indexOf(",")+1, s.length()-1))  - qty;
					if (newqty != 0) { availableItems.get(storage).set(ind,"item("+item+","+newqty+")"); }
					else { remove = ind; }
//					logger.info("@@@@@ List "+availableItems.get(storage)+" already contains "+item+" index "+availableItems.get(storage).indexOf(s));
				}
			}
			if (remove != -1) {  availableItems.get(storage).remove(remove); }
		}
		String[] itemsAux = availableItems.get(storage).toArray(new String[availableItems.get(storage).size()]);
		this.removeObsPropertyByTemplate("available_items", storage, null);
		this.defineObsProperty("available_items", storage, itemsAux);
	}
	
	@OPERATION void addServerName(String agent, String agentServer){
		agentNames.put(agent,agentServer);
	}
	
	@OPERATION void getServerName(String agent, OpFeedbackParam<String> agentServer){
		agentServer.set(agentNames.get(agent));
	}
	
	@OPERATION void addRole(String agent, String role){
		agentRoles.put(agent,role);
	}
	
	@OPERATION void addLoad(String agent, int load){
		loads.put(agent,load);
	}
	
	@OPERATION void getLoad(String agent, OpFeedbackParam<Integer> load){
		load.set(loads.get(agent));
	}
	
	@OPERATION void addShopItem(String item, int qty, String itemId, int price){
		shopItemsQty.put(item,qty);
		if (itemsQty.containsKey(itemId)) {
			if (itemsQty.get(itemId) < qty) {
				itemsQty.replace(itemId, qty);
			}
		}
		else {
			itemsQty.put(itemId, qty);
		}
		if (itemsPrice.containsKey(itemId)) {
			if (itemsPrice.get(itemId) < price) {
				itemsPrice.replace(itemId, price);
			}
		}
		else {
			itemsPrice.put(itemId, price);
		}
	}
	
	@OPERATION void getShopItem(String item, OpFeedbackParam<Integer> qty){
		qty.set(shopItemsQty.get(item));
	}
	
	public static int getLoad(String agent) {
		return loads.get(agent);
	}
	
	public static String getAgentRole(String agent) {
		return agentRoles.get(agent);
	}
	
	public static int getItemQty(String item) {
		return itemsQty.get(item);
	}
	
	public static int getItemPrice(String item) {
		return itemsPrice.get(item);
	}
		
	@OPERATION void addResourceNode(String resourceId, double lat, double lon, String resource){
		ObsProperty prop = this.getObsPropertyByTemplate("resNode", resourceId,lat,lon,resource);
		if (prop == null) {
			this.defineObsProperty("resNode",resourceId,lat,lon,resource);
		}
	}
	
	@OPERATION void clearMaps() {
		shopItemsQty.clear();
		agentNames.clear();
		loads.clear();
		availableItems.clear();
		this.init();
	}
	
}