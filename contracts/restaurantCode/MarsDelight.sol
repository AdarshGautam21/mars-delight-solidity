//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;


contract MarsDelight{
  struct Item {
    string name;
    uint256 price;
    bool disabled;
  }

  struct Restaurant {
    address payable owner;
    uint256 fund;
    string name;
    string addr;
    uint256 areaId;
    uint256 itemId;
    mapping(uint256=> Item) items;
    // Item[] items;
  }

  struct User {
    string name;
    string addr;
    uint256 phoneNo;
  }

  struct Order {
    address payable orderer;
    address payable deliverer;
    uint256 fund;
    uint256 restaurantId;
    uint256[] items;
    uint256[] quantities;
    uint256 areaId;
    string fullAddress;
    bool isCanceled;
    bool restaurantApproved;
    bool pickupConfirmed;
    bool orderReceived;
    bool reclaimed;
    uint256 orderTime;
  }

 //
  address admin = msg.sender;
  string[] areas;
  uint commissionRate = 10;
  uint lockedRate = 50;
  uint256 deliveryFee = 100;
  uint maxDeliveryTime = 60;

  modifier isAdmin() {
    require(msg.sender == admin);
    _;
  }

  function addArea(string memory area) public isAdmin {
   
    areas.push(area);
  }

  function getArea(uint256 id) public view returns(string memory area){
    return areas[id];
  }

  function getAreas() public view returns(string[] memory){
    return areas;
  }

  // function checkAreaExists(string memory area) private view returns(bool found){
  //     for (uint i=0; i<areas.length; i++) {
  //         if(StringUtils.equal(areas[i], area)) return true;
  //     }
  //     return false;
  // }


  // Restaurant methods
  // mapping(uint256 => Restaurant) restaurants;
  Restaurant[] restaurants;
  uint256 counter;
  uint256 restaurantId;


  function addItem(uint256 id, string memory name, uint256 price) public {
    Restaurant storage restaurant = restaurants[id];
    require(restaurant.owner == msg.sender);
    restaurant.items[restaurant.itemId] = Item(name, price, false);
    restaurant.itemId++;
  }

  function getItem(uint256 restId, uint256 itemId) public view
  returns (string memory name, uint256 price){
    Item storage item = restaurants[restId].items[itemId];
    return (item.name, item.price);
  }


  // User mathods
  mapping(address => User) users;

  function register(string memory name, string memory addr, uint256 phoneNo) public {
    User memory user = User(name, addr, phoneNo);
    users[msg.sender] = user;
  }

  // Orderer methods
  Order[] orders;

  function placeOrder(uint256[] memory items, uint256[] memory quantities, uint256 areaId,
    string memory fullAddress, uint256 restId) public payable {
    // add requires
    Order memory order;
    order.orderer = payable (msg.sender);
    order.items = items;
    order.quantities = quantities;
    order.areaId = areaId;
    order.fullAddress = fullAddress;

    Restaurant storage restaurant = restaurants[restId];
    require(restaurantIsAvailable(restaurant, order.fund), "Restaurant is unable to deliver");
    order.restaurantId = restId;
    // calculate prices
    uint256 price = 0;
    for(uint i=0; i <items.length; i++){
      price += restaurants[restId].items[items[i]].price * quantities[i];
    }
    require(msg.value == price + deliveryFee , "Not enough fund sent.");

    order.fund = price;
    order.orderTime = block.timestamp;
    orders.push(order);
    //event
    emit newOrder(orders.length -1, restaurant.owner);
  }

  function getOrder(uint256 id) public view returns(Order memory){
    return orders[id];
  }

  function cancelOrder(uint256 orderId) public {
    Order storage order = orders[orderId];
    require(order.orderer == msg.sender && !order.isCanceled
      && order.deliverer != address(0));
     order.isCanceled = true;
    // transfer fund
    payable(msg.sender).transfer(order.fund + deliveryFee);
    if(order.restaurantApproved){
      // unlock deliverer commission
               Restaurant storage restaurant = restaurants[order.restaurantId];
                 restaurant.owner.transfer(calculateCommission(order.fund));
    }
    // event
    emit orderCanceled(orderId, order.orderer);
  }

  function receiveOrder(uint256 orderId) public {
    Order storage order = orders[orderId];
          require(order.orderer == msg.sender);
      require(!order.orderReceived && !order.isCanceled && order.deliverer != address(0));
            order.orderReceived = true;
           order.fund = 0;
           // transfer
    uint256 commission = calculateCommission(order.fund);
    order.deliverer.transfer(order.fund + (order.fund/100) * lockedRate + deliveryFee + commission);
  }

  function approveOrder(uint256 orderId) public {
           Order storage order = orders[orderId];
           Restaurant storage restaurant = restaurants[order.restaurantId];

          require(restaurant.owner == msg.sender);
               order.restaurantApproved = true;
    
          restaurant.fund -= calculateCommission(order.fund);
    
          emit orderApproved(orderId, order.orderer);
  }

  function calculateCommission(uint256 fund) private view returns(uint256){
    return (fund/100)* commissionRate;
  }

  function searchAreaRestaurant(uint256 areaId) public view
  returns(uint256[] memory, string[] memory, string[] memory) {
    uint256 totalMatch = 0;
    for(uint256 i=0; i<restaurants.length; i++){
      Restaurant storage restaurant = restaurants[i];
      if(restaurant.areaId == areaId  && restaurantIsAvailable(restaurant, 100)){
        totalMatch++;
      }
    }
    uint256[] memory restIds = new uint256[](totalMatch);
    string[] memory names = new string[](totalMatch);
    string[] memory fullAddrs = new string[](totalMatch);

    totalMatch = 0;
    for(uint256 i=0; i<restaurants.length; i++){
      Restaurant storage restaurant = restaurants[i];
      if(restaurant.areaId == areaId  && restaurantIsAvailable(restaurant, 100)){
        restIds[totalMatch] = i;
        names[totalMatch] = restaurant.name;
        fullAddrs[totalMatch] = restaurant.addr;
        totalMatch++;
      }
    }

    return(restIds, names, fullAddrs);
  }

  function restaurantIsAvailable(Restaurant storage restaurant, uint256 price) private view returns(bool){
    return restaurant.fund >= (price/100)* commissionRate;
  }

  function reclaim(uint256 orderId) public {
    Order storage order = orders[orderId];
    require(msg.sender == order.orderer, "Access rejected.");
    require(!order.isCanceled && !order.orderReceived &&
    !order.reclaimed, "Invalid reclaim request.");
    require(order.orderTime + maxDeliveryTime * 1 minutes < block.timestamp, "Try after max order duration.");

    uint256 ordererAmount = (order.fund/100) * lockedRate + order.fund + deliveryFee; // deliverer locked + oderer locked.
    order.orderer.transfer(ordererAmount);

    if(order.restaurantApproved){
      // unlock deliverer commission
      Restaurant storage restaurant = restaurants[order.restaurantId];
      restaurant.owner.transfer(calculateCommission(order.fund));
    }
    if(order.deliverer == address(0)){
      order.deliverer.transfer(order.fund);
    }
    order.fund = 0;
    order.reclaimed = true;
  }

  event newRestaurant(uint256 restaurantId);
  event newOrder(uint256 orderId, address restaurant);
  event orderCanceled(uint256 orderId, address orderer);
  event orderApproved(uint256 orderId, address orderer);
  event orderAccepted(uint256 orderId, address deliverer, address restaurant);
  event orderPickedup(uint256 orderId, address orderer);
  // event orderDelivered(uint256 orderId, address orderer);

  function genEvent(uint option) public {
    if(option == 0){
      emit newRestaurant(0);
    } else if(option == 1){
      emit newOrder(0, 0x02d91Ba6b954cfA50b2Dd685212dAE7Cf26B52B9);
    } else if (option == 2){
      emit orderCanceled(0, 0x7E3d972A5916B6dD9b3d518BF8f36D891CECB910);
    } else if (option == 3){
      emit orderApproved(0, 0x7E3d972A5916B6dD9b3d518BF8f36D891CECB910);
    } else if(option == 4){
      emit orderAccepted(0, 0xbfb21c004EEDc4229d30485E09fcA941eB76223A, 0x02d91Ba6b954cfA50b2Dd685212dAE7Cf26B52B9);
    } else if(option == 5){
      emit orderPickedup(0, 0x7E3d972A5916B6dD9b3d518BF8f36D891CECB910);
    }
    // else if(option == 5){
    //     emit orderDelivered(0, 0x7E3d972A5916B6dD9b3d518BF8f36D891CECB910);
    // }
  }

}