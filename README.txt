A simple solidity contract for the Ethereum blockchain, that provides many functionalities.




1- the offer_valid_time argument in the functions (CarPropose, PurchasePropose) is given in terms of days.
	example: CarPropose (car_id, price, 5) means that starting from now, the offer is valid for 5 days.

2- the driver's salary is set to 1 ether in the constructor.

3- the constructor transaction cost is 3,133,047 gas.
	 so if 4,000,000 is provided when deploying the code it should deploy successfully.
