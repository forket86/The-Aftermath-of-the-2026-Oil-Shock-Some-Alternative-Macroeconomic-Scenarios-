******* INSTRUCTIONS  ************************
1. Run commodity_prices.m. 
	- This produces the futures price data used in calibrating Figs 	  2, 3, and 4 (oil price expectations as of March).
2. Run fig1.m 
	- In addition to fig1.png, this script produces the historical 	 	  (1979-80) price data used to calibrate the 1970s exercise in 	  	  Fig 4. 
3. Run Fig2.m, Fig3.m, and Fig4.m to create remaining figures



******* OUTPUT LOCATION ************************
Graph output will be viewable in ./figures_png/. 


******* DEPENDENCIES ***************************
To run Fig2.m, Fig3.m, and Fig4.m, you will need to have Dynare 7.0 installed. At the top of these scripts, you'll see a Boolean called AleDirectory. Set to 1 if you are running on Mac, 0 if you are running on PC. 