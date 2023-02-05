//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
 
contract shopping{
 
    address payable public owner;
 
    constructor (){
        //making the deployer of the contract owner
        owner = payable(msg.sender);
    }
 
    struct Seller{
        string name;
        address addr;
        uint value;
        bool completed;
    }
 
    mapping(address=>Seller) public sellers;
 
    struct Buyer{
        string name;
        string email;
        string deliveryAddress;
        bool completed;
    }
 
    mapping(address=>Buyer) buyers;
   
    struct Product{
        string title;
        string desc;
        string video;
        string image;
        string productId;
        uint price;
        address payable seller;
        address payable buyer;
        bool isActive;
        uint256 deliverdTime;
        bool delivered;
    }

    mapping (address=>Product[]) sellerProductList;
    mapping(string=>Product) public products;
    Product[] public allProducts;

    struct ProductState{
        string productId;
        uint price;
        uint updateTime;
        bool delivered;
        string location;
        string estimatedDate;
        address buyer;
        address seller;
        address update;
    }

    mapping(string=>ProductState) public productState; 

    struct ProductUnique{
        string productId;
        bool isActive;
        bool isPurchased;
        bool isCancel;
    }

    mapping(string => ProductUnique) ProductData;
 
   //Registering as a seller
    function sellerSignup(string memory _name) public payable{
        require(!sellers[msg.sender].completed,"You are already signed up");
        require(msg.value==2,"Value is not sufficient");
        require(bytes(_name).length>0,"_name field can't be empty.");
        owner.transfer(msg.value);
        sellers[msg.sender].name=_name;
        sellers[msg.sender].addr=msg.sender;
        sellers[msg.sender].value=msg.value;
        sellers[msg.sender].completed=true;
    }
 
    //Registering as a buyer(If they want to buy a product)
    function buyerSignup(string memory _name, string memory _email, string memory _deliveryAddress) public{
        require(!buyers[msg.sender].completed,"You are already signed up");
        require(bytes(_name).length > 0,"_name field should be greater than 3 spaces");
        require(bytes(_email).length> 0,"_email field should be greater than 10 spaces");
        require(bytes(_deliveryAddress).length> 0,"_deliveryAddress field should be greater than 20 spaces");
        buyers[msg.sender].name = _name;
        buyers[msg.sender].email = _email;
        buyers[msg.sender].deliveryAddress = _deliveryAddress;
        buyers[msg.sender].completed = true;        
    }
 
    //Seller Listing the products( after signing up )
    function listingProduct(string memory _title, string memory _desc,string memory _video, string memory _image, string memory _productId ,uint _price) public{
        require(sellers[msg.sender].completed,"!!You have not signed up!!,Please signup to list the products");
        require(bytes(_title).length > 0,"Title field can't be empty");
        require(bytes(_desc).length>0,"Description field can't be empty");
        require(bytes(_video).length>0,"Video field can't be empty");
        require(bytes(_image).length>0,"Image field can't be empty");
        require(bytes(_productId).length>3,"ProductId should be greater than 3 characters");
        require(_price > 0,"Price should be greater than zero");
        require(!ProductData[_productId].isActive, "Product with same productId already exist");
        ProductData[_productId] = ProductUnique(_productId, true, false,false);
        products[_productId] = Product(_title, _desc, _video, _image, _productId,  _price, payable(msg.sender),products[_productId].buyer,true, 0, false);

        Product memory tempProduct;
        tempProduct.title = _title;
        tempProduct.desc = _desc;  
        tempProduct.video = _video;
        tempProduct.image = _image;
        tempProduct.productId = _productId;
        tempProduct.price = _price;  
        tempProduct.seller = payable(msg.sender);
        tempProduct.isActive = true;
        allProducts.push(tempProduct);
        sellerProductList[msg.sender].push(tempProduct);
    }
    
    //Sellers can see their listed products
    function sellerProducts(uint _index) public view returns(string memory title, string memory desc,string memory video, string memory image, string memory productId, uint price,bool isActive) {                
      return(sellerProductList[msg.sender][_index].title, 
             sellerProductList[msg.sender][_index].desc,  
             sellerProductList[msg.sender][_index].video, 
             sellerProductList[msg.sender][_index].image, 
             sellerProductList[msg.sender][_index].productId, 
             sellerProductList[msg.sender][_index].price,
             sellerProductList[msg.sender][_index].isActive
        );                
    }

    //Placing an order
    function placeOrders(string memory _productId) public payable{
        require(buyers[msg.sender].completed,"Please register yourself");
        require(ProductData[_productId].isActive == true, "Product with this productId does not exist");
        require(ProductData[_productId].isPurchased == false, "Product with this productId is already purchased.");
        require(msg.value==products[_productId].price,"Pay the accurate amount");
        require(bytes(_productId).length>3,"ProductId should be greater than 3 characters");
        products[_productId].buyer=payable(msg.sender);
        owner.transfer(msg.value);
        ProductData[_productId].isPurchased = true;
        ProductData[_productId].isCancel=false;
    }

     //Update shipmentStatus
    function updateShipment(string memory _productId,address _buyer,string memory _location, string memory _estimatedDate,address _update) public{
        require(products[_productId].seller==msg.sender || productState[_productId].update == msg.sender,"You don't have the authority to update shipment status.");
        require(products[_productId].buyer==_buyer,"Wrong productId or buyer address, Please try again"); 
        require(bytes(_productId).length>3,"ProductId should be greater than 3 characters");
        require(_buyer != address(0));
        require(_update != address(0));
        require(bytes(_estimatedDate).length>5);
        productState[_productId] = ProductState(_productId,products[_productId].price,block.timestamp,products[_productId].delivered,_location,_estimatedDate,_buyer,products[_productId].seller,msg.sender);
        productState[_productId].update = _update;
    }
 
    //Delivery Confirmation
    function deliveryStatus(string memory _productId) public {
        require(products[_productId].buyer==msg.sender,"Only buyer can confirm it");
        require(!products[_productId].delivered,"You have already confirmed the delivery status");
        require(bytes(_productId).length>3,"ProductId should be greater than 3 characters");
        products[_productId].delivered = true;
        ProductData[_productId].isPurchased = true;
        products[_productId].deliverdTime = block.timestamp;
    }
    
    //Buyer can cancel the order
    function cancelOrder(string memory _productId) public {
        require(bytes(_productId).length>3,"ProductId should be greater than 3 characters");
        require(products[_productId].buyer==msg.sender,"Only buyer can cancel it"); 
        require(ProductData[_productId].isCancel==false,"Oops... you already canceled the order");
        ProductData[_productId].isPurchased=false;
        ProductData[_productId].isCancel=true;     
    }

    //owner transfering wei to seller after 7 days since buyer have comfirmed the delivery status i.e true
    function ownerPriceTransfer(string memory _productId) public payable{
        require(owner==msg.sender,"Only owner can call this function");
        require(products[_productId].delivered == true ,"Delivery status is not confirmed yet");
        require(bytes(_productId).length>3,"ProductId should be greater than 3 characters");
        require(block.timestamp>products[_productId].deliverdTime + 7 days,"Please wait for 7 days");
        products[_productId].seller.transfer(products[_productId].price);
    }

    //Refund Order(only owner) to buyer
    function refundOrder(string memory _productId,address _buyer) public payable{
        require(owner==msg.sender,"Only owner can refund the order");
        require(products[_productId].buyer==_buyer,"Its not the correct buyer address");
        require(ProductData[_productId].isPurchased==false,"Buyer have not cancel the order yet");
        require(bytes(_productId).length>3,"ProductId should be greater than 3 characters");
        products[_productId].buyer.transfer(products[_productId].price);
        products[_productId].buyer=payable(address(0));
        ProductData[_productId].isPurchased=false;
    }    
}
 


