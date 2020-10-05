# What does it take to build an iphone app?
Jim Zucker, September 2009 to Feb 2010

<img width="225" height="225" align="left" src="https://github.com/jimzucker/iCDS/blob/master/images/512_iCDS_Icon.jpg">

It took me about $2,427 bucks, over 5 months and 134 hours of my time. 

I probably should have started blogging at the start of the project last September (2009), but I am still learning the ins and outs of the wiki site. On the 28th of Jan I submitted the App to the AppStore, so now I am waiting (what I hope is a couple of days) to publish my first app.

I started this project when as a 'former' Mac developer I was swept up by the excitement of the iPhone App phenomenon. This led me to a drive to get a non-trivial application into the App Store. I convinced my family to buy me a MacBookPro for my birthday in Sept, 2009 and about 20 hours of effort latter I had my first GUI prototype running on the simulator.

Along the way I have learned a lot about the rich environment of information sharing now happening in the development community. I was reintroduced to the Apple Development Tools (XCode) and the Snow Leopard OS. Not having touched MPW(Macintosh Programmers Workshop) in over 15 years, it was like I never left home with the added power of the underlying LINUX environment that I am well versed in using every day at work. I then was introduced to new resources including ITunes U, blogs and code.google.com .

The 1.0 version of the application will implement a SNAC(Standard North American CDS), upfront fee calculator using the ISDA Standard CDS Model, www.cdsmodel.com and based on the functionality found on the MarkIt partners website, www.markit.com/cds. The applications free. Its only objective is for the author to have a non-trivial application in the iPhone AppStore. The approach of the application is to recalculate the upfront fee and intermediate results and display them as the user changes inputs using the quick entry controls or the pickers accessed by pressing the buttons displaying the inputs.
Costs: about $2,4,27

	$1400 - 1 MacBook Pro
	$99.00 - Apple Iphone Developer Enrollement
	$149 - Send in copy right info to the cpy right people
	$30 - For some design paper and template I never used.
	$299 - Ipod touch, after I found out you need a device!
	$60/month - for a verizon hotspot so my app can access ther internet (reallly wish verizon had an IPhone)
	$150 - File a copyright
	134 Hours of my time ... PRICE LESS
 
It is an exciting journey creating my first iPhone Application, here is my journal: (Sep 2009 - Feb 2010 132 hours)

* 1 Sept 2009- My adventure can start, my wife and kids gave me a Macbook Pro for my birthday
* 8 hours to setup XCode, create "Hello World" and run thru the first 2 Stanford ITunes U-courses.
* 2 hours to download the source from www.cdsmodel.com and get the test app running on the command line on the Mac
	> Hint
	> The compiler paths in the Makefiles needed to be fixed, no code changes required!
* 3 hours to move it to XCode and play with it to understand how it works.
* 4 hour to create my first version of the GUI and get it working from XCode
* 6 hours to hook it together and get # on the screen, it was an exciting milestone when I saw the accrued interest tied out to the reference implementation.
Hint
Check out the Article, <<http://tutorialdog.com/how-to-create-icons-for-mac-os-x/>>
	> Hint
	> Great website for creating icons, <<http://www.flavorstudios.com/iphone-icon-generator>>
* 4 hours! to sort out how the complexities of icons on the iPhone and create one
* 8 hours tinkering with icons and doing several revisions of the GUI
* 3 hours wasted trying to register my app on the iPhone App Store, got frustrated after I learned I needed a support website. Will try again another day.
* 10 hours to sort out how to download a zip file from a URL that contains multiple files and display the date in GUI
	> Hint
	> Thanks to Google Code and Gillies Vollant for mini zip! <<http://code.google.com/p/ziparchive/>>
* 4 hours trying to merge a new 'vew' for the Libor Curve into the main app from a test bed
	> Hint
	> Found a good link on this: http://www.amateurinmotion.com/articles/2009/01/24/creating-uitabbarcontroller-based-app-using-interfacebuilder.html
* 1 hour to submit an application to the iphone store, it is hard to get the icon and screenshots in acceptable sizes so they pass vaildations.
* 3 hours to sourt out merging the applications, hit my first real iPhone programing specific issues, it turn out to be a fundimental concepts problem. As the sample code I used for each component was a stand alone app, the developers did things at an application object level so to merge them I had to change each testbed into a view.
* 1.5 hours factoring the ISDA calculator sample programs interface to accept libor as an input.
* 3 hours refactoring the parsing of the Libor Curve to feed into the calc
* 2.5 hours lost, the app runs on the simulator but failes on the device ;(
* 2 hour working with the date routines in the IDSA libraries, looks like the way to go. Hit a snag the libor website is not available, time to impliment some error handling and user alerts.
* 3.5 hours implimented error handling for accessing markit site, played with GUI elements and skimmed throught the UI guidlines docs. - The Segement control has a couple of styles, the bar style is nice but small and hard to read.
	> Hint
	> It is unclear if apple does not want you to change the labels on a switch and limits its use to on/off.
* 6 hours - learned how to use the picker control (while riding to Canada for Skiing), the sample code from Apple was great
	> Hint
	> Buttons are a little funny, you have to set all states via setTitle to change them
	> If you dont have space for an activity indicator, you can use: [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
* 9 hours over 4 days to add pickers and validations to all of the text fields, they are now buttons with proper input interfaces.
* 7.5 hours and I am having a great new year, I have a $1.00 error, otherwise I match on the 10 odd tests I just ran through. Oddly I found some of the defaults it the sample LINUX code where wrong, not sure if I did it or it came that way. They key to sorting this was going through the xls example an running through the test matrix in the documentation for about 12 odd trades.
	> Trivia
	> I learned that MAC Office 2008 does not support VB, so I can't run the Markit plugin, need to download open office and try and get it running so I can > compare to the reference implimentation.
* 2 hours working on the interface to clean it up. I found making icons for the tabbar controler particularly difficult, I learned they should be 30x30 and are complex to create, fortunately I found somebody else has solved the problem for me.
	> Hint
	> To create tabbar icons, check out "iPhone icon generator" by Scott Penberthy, it is a great tool. <<http://scottpenberthy.com/tab/>

	> Hint
	> There are alot of icons available for free on the internet for the in phone:
	> - Color icons and buttons:<<http://downloadpedia.org/Free_Icons_and_Buttons>>
	> - Tabbar 30x30 icons: <<http://glyphish.com/>>

* 6 hours playing with different interface designs and color schemes
	> Hint
	> Found a great set of keyboard buttons at <<KeyboardIcons.com>>
* 3 hours setting up virtual PC on my mac and getting windows and excel loaded, so I can run the MarkIt xls to prove out the # in the calculator.
* 2 hours discussing the project with my nieghbor and getting advice on the interface design.
* 2.5 hour making changes my friend recommended to make the textfields white and rounded corners 2 hour testing, accrued interest one dollar off, exactly 1 dollar so that is a bug. Good news is fee is tying out!
* 2.5 hours testing, figured out the $1 accrued interest, it was a bug introduced by the buy/sell button. Worked out that I am a few cents off with a 1 Year, 1 MM trade, but if go to a 20Y, 20MM trade the error is larger, not sure the cause yet.
* 2 hours - Solved a problem wherer the entire done button was not active.
	> int
	> Found the problem and solution on wiki: <<http://stackoverflow.com/questions/1197746/uiactionsheet-cancel-button-strange-behaviour>>
* 1.5 hours TESTING..TESTING..TESTING - still off $1 in some cases, precision of the clean price does not match the website after the 5th decimal. Time Speng:
* 1 HourTesting the Application I found the pattern in the calculation error: Test Trade: 20MM/10Y, 1000 Fixed, 100 Quoted spread Date Range: 30Dec-14Jan Test Results: (There is a clear pattern!) Mondays - Accrual and Fee match Tuesdays - Match Wed - Accraul matches, fee is off 28-36 USD Thurs - Accrual matches, fee is off 1 USD Fri - Accrual is off .01 USD and fee matches
* 2 hours playing with the test cases to come up with a strategy to debug the problem on wed.
* 2.5 hours - testing
* 3 hours - Figured out the break. Turned out to be the constructions of the riskfree curve was incorrect. I narrowed it down by testing and finding chaning the spread effected the difference between the app and markit xls pluggin. Reviewing the XLS code, I found it has logic to move the dates to a valid business date for each instrument when converting from a date interval, ie 1Y to a real date. The code in the linux sample code is missing this logic.
* 3 Hours - updated GUI to make the trade date a button and started work to support upfront fee in addition to quoted spread. Need to look at current quoting conventions to set the precision correctly for bp and % upfront. Comming accross alot of interesting reading on the internet, but I'm going to take a short cut and talk to my college buddy who works in Sales to review the conventions.
* 5 Hours - Cleaned up the icon for the buttons, researched how to make a more complex AlertView for supporting a user entering spreads or fees, had to do it in a test bed and will port into the app next week. The bulk of the time was learning how to create proper view/controllers, found a great tutorial on the web. Unfortunately the prior structure for the Alert dialogs when a user clicks a button did not port easily, but the new approach is much better, less procedural.
	> Hint
	> Read this tutorial on view/controller, "iPhone Programming Fundamentals: Understanding View Controllers" , <<http://www.devx.com/wireless/Article/42476/>>
* 2 hours - adding the reachability network awareness requirement from Apple and updating the Info page
* 28 Jan spent $150 to get a copyright submitted
* 28 Jan 2010 - 3 hours - my last entry ;) Re did my icon in proper format, and the app is pending review at the iphone store.
* 4 Feb 2010 - The app is now available in the App Store! It is FREE
