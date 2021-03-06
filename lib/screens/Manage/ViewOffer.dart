// ignore_for_file: file_names, camel_case_types, prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jomshare/constants.dart';
import 'package:jomshare/model/FeedbackRating.dart';
import 'package:jomshare/model/carpool.dart';
import 'package:jomshare/screens/Manage/EditOffer.dart';
import 'package:jomshare/screens/Manage/OfferedBody.dart';
import 'package:jomshare/screens/Manage/ViewHostPassenger.dart';
import 'package:jomshare/screens/Manage/ViewPassenger.dart';
import 'package:jomshare/screens/Manage/manageHome.dart';
import 'package:jomshare/screens/home/home.dart';
import 'package:jomshare/screens/offerpool/AcceptPool.dart';
import 'package:jomshare/screens/welcome/components/body.dart';
import 'package:rating_dialog/rating_dialog.dart';
import 'package:jomshare/model/FeedbackRating.dart';

class viewoffer extends StatefulWidget {
  viewoffer({Key? key, required this.voffer}) : super(key: key);

  final CarpoolObject voffer;

  @override
  State<viewoffer> createState() => _viewofferState();
}

class _viewofferState extends State<viewoffer> {
  CollectionReference carpooldb =
      FirebaseFirestore.instance.collection('carpool');
  updateRequestStatus(DocumentSnapshot snapshot)
  {
    List <dynamic> requestList=snapshot.data()!["requestList"];
    List <dynamic> requestStatus=snapshot.data()!["requestStatus"];
    List <int> indexlist=[];
    for (int g=0;g<requestStatus.length;g++)
    {
      if (requestStatus[g].toString()=="pending")
      {
        indexlist.add(g);
      }
    }
    for (int h=0;h<indexlist.length;h++)
    {
      requestStatus[indexlist[h]]="rejected";
    }
    carpooldb.doc(widget.voffer.pooldocid).set({
      "requestStatus":FieldValue.delete(),
      "requestStatus":requestStatus
    },
    SetOptions(merge: true)
    );
    print("truexxxx");



  }
  Future <void> completeCarpool()
   async {
    widget.voffer.poolstatus="complete";
     var pooldocid2 = widget.voffer.pooldocid;
     DocumentReference carpool= carpooldb.doc(pooldocid2);
    carpool.update(
       {
         'poolstatus': widget.voffer.poolstatus
       },

     );
    await carpool.get().then((value) =>
     {

       if (value.exists)
       {

         if (value.data()!.containsKey("requestList")&&value.data()!.containsKey("requestStatus"))
         {

          updateRequestStatus(value)
         }
       }
     });


  }

  Future<void> deleteCarpool() {
    FirebaseFirestore.instance.collection("user").doc(FirebaseAuth.instance.currentUser!.uid).update({'Offered carpools':FieldValue.arrayRemove([widget.voffer.pooldocid])});
    widget.voffer.requestid.forEach((element) {

 FirebaseFirestore.instance.collection("user").doc(element).update({'Requested carpools':FieldValue.arrayRemove([widget.voffer.pooldocid])});



    });
    return carpooldb.doc(widget.voffer.pooldocid).delete();
  }

  String convert(String x)
  {
    List day=['Mon','Tue','Wed','Thurs','Fri','Sat','Sun'];
    List <String> daylist=x.substring(1).split('/');
    print(daylist);
    String temp="";

    for (int z =0;z<daylist.length;z++)
    {
      for (int m=0;m<day.length;m++)
      {
        if (int.parse(daylist[z])==(m))
        {
          temp=temp+"-"+day[m];
        }
      }
    }
    temp=temp.substring(1);
    print (temp);
    return temp;
  }
  bool checkReadyForComplete ()
  {
    DateTime convertDateTime=DateTime.parse(widget.voffer.datetime);
    if (DateTime.now().isAfter(convertDateTime))
    {
      return true;
    }
    else{
      return false;
    }
  }
  Widget carpoolStatus ()
  {
    String statusWord="";
    Color statusContainerColor;
    if (widget.voffer.poolstatus!=null&&widget.voffer.poolstatus=="complete")
    {

      statusWord="completed";
      statusContainerColor=Colors.green;

    }
    else
    {
      statusWord="on-going";
      statusContainerColor=Colors.blue;
    }

    return Expanded(
                      flex: 1,
                      child: Container(
                        padding: EdgeInsets.fromLTRB(2, 10, 2, 10),


                        decoration: BoxDecoration(
                          color:statusContainerColor,
                          borderRadius: BorderRadius.circular(20)


                        ),
                        child: Text(

                          statusWord.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 17.5,color: Colors.white,fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
  }
  void _showRatingAppDialog() {
    final _ratingDialog = RatingDialog(
      commentHint: 'Tell us your feedback',
      starSize: 30,
      title: Text(
        'Rate This Carpool',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
      ),
      image: Image.asset('assets/image/cover.png'),

      message: Text(
        'Tap a star to set your rating. Add your feedback if you want.',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 15),
      ),
      submitButtonText: 'Submit',
      onSubmitted:(response)
      async {

        FeedbackRating hostfeedback=new FeedbackRating(
          userID: widget.voffer.hostid,
          carpoolID: widget.voffer.pooldocid,
          feedback: response.comment,
          rating: response.rating);
await hostfeedback.createFeedbackRating().then((value) => {
            carpooldb.doc(widget.voffer.pooldocid).update({
           "Host Feedback ID": hostfeedback.feedbackDocID
         }
         )
          });






      }

      );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(child:  _ratingDialog,
      onWillPop: () async => false)
    );
  }
  Widget completeCarpoolButton()
  {
    if (checkReadyForComplete()&&widget.voffer.poolstatus!=null)
    {
      if (widget.voffer.poolstatus!="complete")
      {
        return ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.green),
                    shadowColor: MaterialStateProperty.all(Colors.grey),
                    overlayColor:
                        MaterialStateProperty.all(Colors.red[400]),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                  onPressed: ()  async{
                    completeCarpool().then((value) => {
                   _showRatingAppDialog()



                 }).then((value) => {
                  setState(() {})

                 });




                  },
                  child: Wrap(
                    spacing: 10.0,
                    children: [
                      Icon(
                        Icons.assignment_turned_in_outlined,
                        size: 20.0,
                      ),
                      Text(
                        "Complete carpool",
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ],
                  ),
                );
      }
      return Center();

    }
    else
    {
      return Center();
    }
  }
  @override
  Widget build(BuildContext context) {
    String countPassenger ()
 {
   int numpassenger=0;

  List <String>requestUserId=[];
   print("Status: "+widget.voffer.poolstatus);


   for (int m=0;m<widget.voffer.requestid.length;m++)
   {
     print("yes");
     if (widget.voffer.requeststatus[m]=="accepted")
     {
       requestUserId.add(widget.voffer.requestid[m]);
       print(widget.voffer.requestid[m]);
       numpassenger++;
     }


   }
   return (numpassenger).toString()+"/"+widget.voffer.seatno.toString();

 }
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(Icons.people),
        onPressed: (){
           Navigator.push(context,
                    MaterialPageRoute(builder: (BuildContext context)
                    =>ViewPassenger(request: widget.voffer))
                    );

        },
        label:  Text(

                        "View\npassengers",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15.0),
                      ),),


      // backgroundColor: Colors.grey[100],
      appBar: AppBar(
        actions: [
          IconButton(onPressed: (){
            setState(() {});},
            icon:Icon(Icons.cached_rounded)
          )
        ],
        leading: IconButton(
          onPressed: (){
            Navigator.popUntil(context, ModalRoute.withName('/home'));
            setState(() {

            });
          },
          icon: Icon(Icons.arrow_back),
        ),
        title: const Text("View Detail Information"),
        backgroundColor: lightpp
      ),
      body: SingleChildScrollView(
          // margin: const EdgeInsets.all(10.0),
          // padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15),
          // decoration: BoxDecoration(
          //   color: Colors.white,
          //   border: Border.all(
          //     color: Colors.black12,
          //     width: 1,
          //   ),
          // ),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Container(
          //   padding: const EdgeInsets.only(left: 25.0, right: 25.0, top: 20.0 ),
          //   color: Colors.blueGrey[800],
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Text("Passenger :" ,style: TextStyle(fontSize: 17.5, color: Colors.white.withOpacity(0.85))),
          //       ListView.builder(
          //         shrinkWrap: true, //another solution is use expanded to warp all listview.builder but will use entire screen
          //         padding: const EdgeInsets.all(10),
          //         itemCount: voffer.pname.length,
          //         itemBuilder:(context,index)=>
          //         Container(
          //           margin: EdgeInsets.only(bottom: 15.0),
          //           child: Row(
          //             mainAxisAlignment: MainAxisAlignment.start,
          //             children: [
          //               CircleAvatar(
          //                 radius: 24,
          //                 backgroundImage: AssetImage(voffer.pimage[index]),
          //               ),
          //               SizedBox(width: 10,),
          //               Text(voffer.pname[index], style: TextStyle(fontSize: 17.5, color: Colors.white.withOpacity(0.85)) ),
          //             ],
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          Container(
            padding: const EdgeInsets.only(left: 25.0, right: 25.0, top: 20.0),
            child: Column(
              children: [
                Row(children: [
                  Expanded(
                      flex: 1,
                      child: Text(
                        "Carpool Status :",
                        style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey),
                      ),
                    ),
                    carpoolStatus()



                ],),
                SizedBox(height: 20,),
                Row(children: [
                  Expanded(
                      flex: 1,
                      child: Text(
                        "Carpool Type :",
                        style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        widget.voffer.type+" carpool",
                        style: TextStyle(fontSize: 17.5),
                      ),
                    ),


                ],)
                ,

                SizedBox(height: 20,)
                ,
                Row(children: [
                  Expanded(
                      flex: 1,
                      child: Text(
                        "No of passengers /seats offered :",
                        textAlign: TextAlign.left,
                        style: TextStyle(
                            fontSize: 17.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey),
                      ),
                    ),
                    Expanded(
                    flex: 1,
                    child: Text(
                      countPassenger(),
                      style: TextStyle(fontSize: 17.5),
                    ),
                  ),







                ],),
                SizedBox(height: 20,),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        "Date Time :",
                        style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: widget.voffer.type == "Frequent"
                          ? Text(
                              "Frequent Day: ",
                              style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey),
                            )
                          : Container(),
                    ),
                  ],
                ),
                SizedBox(height: 15.0),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        widget.voffer.datetime,
                        style: TextStyle(fontSize: 17.5),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: widget.voffer.type == "Frequent"
                          ? SizedBox(
                            width: 100,
                            child: Text(
                                convert(widget.voffer.repeatedDay),
                                style: TextStyle(fontSize: 17.5),
                              ),
                          )
                          : Container(),
                    ),
                  ],
                ),
                SizedBox(
                  height: 20.0,
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 150,
                      child: Text(
                      "Starting Point:",
                      style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey),
                    )
                    )

                  ],
                ),
                SizedBox(
                  height: 15.0,
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 260,
                      child:  Text(
                      widget.voffer.start,
                      style: TextStyle(fontSize: 17.5),
                    )
                    )

                  ],
                ),
                SizedBox(
                  height: 20.0,
                ),
                Row(
                  children: [
                    SizedBox(width: 200,
                    child:Text(
                      "Destination:",
                      style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey),
                    ))

                  ],
                ),
                SizedBox(
                  height: 15.0,
                ),
                Row(
                  children: [
                    SizedBox(width: 260,
                    child: Text(
                      widget.voffer.destination,
                      style: TextStyle(fontSize: 17.5),
                    ))

                  ],
                ),
                SizedBox(
                  height: 20.0,
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        "Vehicle Type :",
                        style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        "Plate No :",
                        style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        "Price :",
                        style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15.0),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        widget.voffer.vehicletype,
                        style: TextStyle(fontSize: 17.5),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        widget.voffer.plateNo,
                        style: TextStyle(fontSize: 17.5),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        "RM " + widget.voffer.price.toStringAsFixed(2),
                        style: TextStyle(fontSize: 17.5),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 15.0,
                ),
                // Row(
                //   children: [
                //     Expanded(
                //       flex: 1,
                //       child: Row(
                //         children: [
                //           Text("Contact: ", style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.grey),),
                //           Text(voffer.contact, style: TextStyle(fontSize: 17.5),),
                //         ],
                //       )
                //     ),
                //     Expanded(
                //       flex: 1,
                //       child:
                //         voffer.type=="Frequent"
                //         ?
                //         Row(
                //           children: [
                //             Text("Frequent Day: ", style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.grey),),
                //             Text(voffer.repeatedDay, style: TextStyle(fontSize: 17.5),),
                //           ],
                //         )
                //         :
                //         Container(),
                //     ),
                //   ],
                // ),


                SizedBox(
                  height: 15.0,
                ),
                widget.voffer.poolstatus!=null&&widget.voffer.poolstatus=="complete"?Center():ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.green),
                    shadowColor: MaterialStateProperty.all(Colors.grey),
                    overlayColor:
                        MaterialStateProperty.all(Colors.green[400]),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AcceptPool(accept: widget.voffer)),
                    );
                  },
                  child: Wrap(
                    spacing: 10.0,
                    children: [
                      Icon(
                        Icons.add_circle,
                        size: 20.0,
                      ),
                      Text(
                        "View request",
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ],
                  ),
                ),
                widget.voffer.poolstatus!=null&&widget.voffer.poolstatus=="complete"?Center():ElevatedButton(
                  style: ButtonStyle(
                    shadowColor: MaterialStateProperty.all(Colors.grey),
                    overlayColor:
                        MaterialStateProperty.all(Colors.blue[400]),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => editoffer(eoffer: widget.voffer)),
                    );
                  },
                  child: Wrap(
                    spacing: 10.0,
                    children: [
                      Icon(
                        Icons.edit,
                        size: 20.0,
                      ),
                      Text(
                        "Edit",
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ],
                  ),
                ),
                checkReadyForComplete()?Center():ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.red),
                    shadowColor: MaterialStateProperty.all(Colors.grey),
                    overlayColor:
                        MaterialStateProperty.all(Colors.red[400]),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                  onPressed: () {
                    showDialog(context: context,
                    builder: (context)
                    {
                      return AlertDialog(
                        title: Text('Delete Carpool'),
                        content: Text("Are you sure to delete this carpool?"),
                        actions: [
                          TextButton(
              onPressed: () {
                deleteCarpool();
                 Navigator.push(context, MaterialPageRoute(builder: (BuildContext context)=>Home()));

              },
              child: const Text('Yes'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No'),
            ),

                        ],


                      );
                    });


                  },
                  child: Wrap(
                    spacing: 10.0,
                    children: [
                      Icon(
                        Icons.delete,
                        size: 20.0,
                      ),
                      Text(
                        "Delete",
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ],
                  ),
                ),
                completeCarpoolButton()

              ],
            ),
          )
        ],
      )),
    );
  }
}
