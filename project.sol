pragma solidity ^0.5.2;

contract car{
    address payable [] participants; // dynamic array of addresses, max is 100 address
    uint number_of_participants;
    address manager;
    address payable car_dealer;
    uint max_number_of_participents; // 100
    uint participation_fee; // 100 ether
    string OwnedcarID; // assuming that each byte can represnt a single digit 0->9
    uint last_dividend_payment_date; // the last date in which dividends were paid
    
    // car expenses information
    uint car_expanses; // 10 ether every 6 months
    uint car_expanses_last_payment_date; // the last data in which the car expanses were paid in

    
    // taxt driver information
    uint taxi_driver_last_payment_date;
    address payable taxi_driver; // the driver is identified with an int as its ID
    uint driver_salary; // set to 1 ether in the constructor

    // proposed car information
    string ProposedCar_for_buying_ID; // the car proposed by the car dealer for us to buy
    uint ProposedCar_for_buying_price; // in ether
    uint ProposedCar_for_buying_valid_time; // now + (num_of_days * 1 days)
    
    // proposed purhcase information
    string ProposedCar_for_selling_ID;// the car proposed by us to the car dealer to buy
    uint ProposedCar_for_selling_price; // in ether
    uint ProposedCar_for_selling_valid_time; // now + (num_of_days * 1 days)
    uint number_of_approvals;
    mapping(address => uint)approvals; // mappings of participants who approved to sell the car (key:address, value:1 if approved, other if not)
    address [] approvals_list; // list of participants who approved to sell the car
    
    mapping(address => uint) public accounts; // participants, taxi driver, contract (key:address, value: ether)
    mapping (address => bool) public participants_mapping; // key:address, value: true or false
    
    //////// events /////////
    event member_joined(address new_member);
    event car_dealer_changed(address payable new_dealer);
    event driver_changed(address payable new_driver);
    event charge_paid(uint amount_wei);
    event taxi_driver_salary_paid();
    event car_expanses_paid();
    event car_proposed(string car_id);
    event car_purchased(string car_id);
    event car_sold(string car_id);
    event taxi_driver_paid(address driver, uint amount);
    event dividend_paid(uint particepent_share);
    event dividend_been_collected(address particepent, uint collected_share);
    
    ///// modifiers /////
    modifier isManager() {
    require(msg.sender == manager, "only Manager");
    _; // continue executing rest of method body
}
    modifier isCarDealer(){
        require(msg.sender == car_dealer, "only car dealer");
    _; // continue executing rest of method body
    }
    modifier isParticepent(){
        // if the msg sender is the taxi driver or if he is not a particepent
        require(participants_mapping[msg.sender] == true, "only particepent");
    _; // continue executing rest of method body
    }
    modifier isDriver(){
        require(msg.sender == taxi_driver, "only driver");
        _; // continue executing rest of method body
    }
    
    constructor() public payable{
        manager = msg.sender; // the initial manager is the creator of the contract
        car_expanses = 10 ether; // 10 ether
        participation_fee = 100 ether; // 100 ether
        max_number_of_participents = 100;
        number_of_participants = 0;
        last_dividend_payment_date = now; // the dividend payment date starts when we create the contract
        accounts[address(this)] = 0 ether;
        driver_salary = 1 ether;
        
    }
    
    function join() public payable{
        // the sent ether sould be more than 100 ehter
        // msg.value is in wei unit, but the comparision does the conversion automatically
        require(msg.value >= participation_fee, "sender didn't send enough money");
        // the max number of participants is not filled yet
        require(participants.length < max_number_of_participents, "max number of participants is full");
        
        // transfer the sender the rest of his money
        //if( (msg.sender).send( msg.value - 100 ether) ){
            participants.push(msg.sender); // add him to the participants list
            accounts[address(this)] += 100 ether; // add 100 ether to the contract balance
            accounts[msg.sender] = 0 ether; // the new participant initially has 0 in his account
            participants_mapping[msg.sender] = true; // set this address to true for being a participant
            number_of_participants += 1;
            // fire up the event of a member joining
            emit member_joined(msg.sender);
        //}
        //else{
            //revert(); // the transfer of the rest of the money failed. revert.
        //}
    }
    
    function setCarDealer(address payable new_dealer) isManager public{
        car_dealer = new_dealer;
        emit car_dealer_changed(new_dealer);
    }
   
    function CarPropose(string memory _proposed_car_id, uint price, uint validity_time_in_days)isCarDealer public{
        require(bytes(_proposed_car_id).length == 32, "car ID is less than 32 digit");
        ProposedCar_for_buying_ID = _proposed_car_id;
        ProposedCar_for_buying_price = price; // sent in wei
        ProposedCar_for_buying_valid_time = now + (validity_time_in_days * 1 days);// now plus how many days are stated 
        
        emit car_proposed(_proposed_car_id);
    }
 
    function PurchaseCar() isManager public payable{
        // there is a proposed car
        require(bytes(ProposedCar_for_buying_ID).length != 0, "no purchase proposal is made");
        // if its time has not yet passed
        require(now < ProposedCar_for_buying_valid_time, "the valid time has passed");
        // if the contract have enough money, assuming the driver account is 0, as there is no driver
        require( accounts[address(this)] > ProposedCar_for_buying_price, "not enough ether in the contract's account");
        require(car_dealer.send(ProposedCar_for_buying_price), "sending the money to the car dealer has failed");
        accounts[address(this)] -= ProposedCar_for_buying_price; // subtract the paid money from the contract's balance
        
        car_expanses_last_payment_date = now;// the expnases payment starts at the time of the car purchase
        OwnedcarID = ProposedCar_for_buying_ID;
        emit car_purchased(ProposedCar_for_buying_ID);
    }
    
    function PurchasePropose(string memory _ProposedCar_for_selling_ID,uint _ProposedCar_for_selling_price, 
                             uint _ProposedCar_for_selling_valid_time_in_days) public isCarDealer{
                    
            ProposedCar_for_selling_ID = _ProposedCar_for_selling_ID;
            require(bytes(ProposedCar_for_selling_ID).length == 32, "no car with this ID is found");// check if we have the car

            ProposedCar_for_selling_valid_time = now + (_ProposedCar_for_selling_valid_time_in_days * 1 days);
            ProposedCar_for_selling_price = _ProposedCar_for_selling_price; // in wei
            number_of_approvals = 0;
    }
    
    function ApproveSellProposal() isParticepent public{
        require(now < ProposedCar_for_selling_valid_time,"time validity has passed");
        require(bytes(ProposedCar_for_selling_ID).length == 32, "no valid car purchase proposal is found");
        require(approvals[msg.sender] == 0, "participant has already voted"); // participant didn't approve before
        approvals[msg.sender] = 1;
        approvals_list.push(msg.sender);
        number_of_approvals += 1;
    }
    
    function SellCar() public payable isCarDealer{
        require(ProposedCar_for_selling_valid_time > now, "valid time has passed");
        require(number_of_approvals > (number_of_participants/2) , "the approval is less than half");

        // take the card dealer's money
        // transfer the sender the rest of his money
        require( msg.value >= ProposedCar_for_selling_price, "ether sent by car dealer is not enough");
            emit car_sold(OwnedcarID);
            
            // reset all the values realted to the car
            OwnedcarID = "";
            ProposedCar_for_selling_price = 0;
            ProposedCar_for_selling_valid_time = 0;
            ProposedCar_for_selling_ID = "";
            number_of_approvals = 0;
            // reset the values related to the voting process
            for (uint i=0; i<approvals_list.length; i++) {
                approvals[approvals_list[i]] = 0; // set the approval state of the participant to 0
                approvals_list[i] = address(0); // set the address of the approver to 0
            }
        
    }

    function setDriver(address payable new_driver) isManager public{
        require( bytes(OwnedcarID).length == 32, "no car is found for the drivee to use");
        taxi_driver = new_driver;
        taxi_driver_last_payment_date = now; // we start counting the days for payment from the day he starts working
        emit driver_changed(new_driver);
    }
    
    function GetCharge() public payable{
        accounts[address(this)] += msg.value; // add the given charge to the contract's account
        emit charge_paid(msg.value);
    }
    
    function PaySalary() isManager public payable{
        // there is a taxi driver
        require(taxi_driver != address(0), "there is no taxi driver");
        // 30 days have passed since last payment
        require((now - taxi_driver_last_payment_date) > 30 days, "30 days haven't passed yet");
        // does the contract have ether over 1
        require(accounts[address(this)] > driver_salary, "the contract doesn't have enough ether");
        
        accounts[address(this)] -= driver_salary;
        // put the money in the driver acount
        accounts[taxi_driver] += driver_salary;
        emit taxi_driver_salary_paid();
        taxi_driver_last_payment_date = now;
    }

    function GetSalary() public isDriver{
        // successful sending of money to the driver
        if(taxi_driver.send( accounts[taxi_driver]) ){
            emit taxi_driver_paid(taxi_driver, accounts[taxi_driver]);
            accounts[taxi_driver] = 0 ether;
        }
        // payment isn't successful
        else{
            revert();
        }
    }
    
    function CarExpanses() isManager public payable{
        // there is a car dealer
        require(car_dealer != address(0), "no car dealer is found");
        // it has been six months since the last payment, assuming 6 months are 182 days
        require( (now - car_expanses_last_payment_date) > 182 days, "6 months havn't passed yet");
        // the contract has enough money
        require(accounts[address(this)] > car_expanses, "the contract doesn't have enough money");
        // if ether was transfered successfully
        if(car_dealer.send(car_expanses)){
            emit car_expanses_paid();
            accounts[address(this)] -= car_expanses;
            car_expanses_last_payment_date = now;
            }
        else{
            revert();
        }
    }
     
    function GetDividend() isParticepent public payable{
        require( (msg.sender).send(accounts[msg.sender]), "sending the dividend to the participant has failed");
        emit dividend_been_collected(msg.sender, accounts[msg.sender]);
        // his account is now empty
        accounts[msg.sender] = 0;
        
    }
    
    function payDividend() isManager public payable{
        // 6 months is 182 days
        require( (now - last_dividend_payment_date) > 182 days, "6 months haven't passed yet");
        // assuming that the driver/car_expanses are paid on time
        uint participant_share = (accounts[address(this)]) / participants.length ;
        
        // subtract the shares of every participant from the contract's account
        accounts[address(this)] -= (participant_share * participants.length);
        // for each participant put his share in his account
        for (uint i=0; i < participants.length; i++){
            accounts[ participants[i] ] += participant_share;
        }
        emit dividend_paid(participant_share);
    }
   
    function ()external{
        // does nothing
    }
    

}