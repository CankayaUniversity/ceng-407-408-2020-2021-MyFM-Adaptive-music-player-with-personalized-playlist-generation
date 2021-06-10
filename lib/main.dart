import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart';
import 'AuthenticationServices.dart';
import 'Customer.dart';
import 'LoginPage.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

final Dbs d = new Dbs();
final Color color = Colors.deepOrangeAccent;
final Color innerColor = Colors.white;
List<Song> songs, nSongs;
String path, toPlay, individualArtist, pictureLocation;
List<String> likes, filesInDir;
int page;
Directory directory;
List<Song> copyNSong = new List<Song>.empty(growable: true);
Song currentPlaying, currentLoaded;
Music previousMusic;
int next = 1, selectedIndex;
bool connected = true,
    moveSong,
    shutChecked = false,
    beingUsed = false,
    back = false,
    loopToggle = false,
    playListChange = true,
    shuffleToggle = false,
    songsLoaded = false;
List<String> playLists = new List<String>.empty(growable: true);
List<String> playlistNames = new List<String>.empty(growable: true);
final AudioPlayer ap = new AudioPlayer();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FlutterDownloader.initialize(debug: true);
  d.initialize();
  directory = await getExternalStorageDirectory();
  filesInDir = new List<String>.empty(growable: true);
  await for (var file in directory.list(recursive: false, followLinks: false))
    filesInDir.add(file.path);
  songs = List.empty(growable: true);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
      Phoenix(
       child: MaterialApp(
    debugShowCheckedModeBanner: false,
    title: "MyFm",
    home: Initial(),
  )));
}
class Initial extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthenticationServices>(
          create: (_) => AuthenticationServices(FirebaseAuth.instance),
        ),
        StreamProvider(
          create: (context) =>
          context.read<AuthenticationServices>().authStateChanges,
        )
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AuthenticationWrapper(),
      ),
    );
  }
}

class ForgotPassword extends StatelessWidget {
  final forgetEmail = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: color,
        title: Text("Reset password"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              child: TextField(
                controller: forgetEmail,
                textAlign: TextAlign.center,
                decoration: InputDecoration(hintText: "Enter your email..."),
              ),
            ),
            Container(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(primary: color),
                  onPressed: () async {
                    String result = await context
                        .read<AuthenticationServices>()
                        .forgetPassword(email: forgetEmail.text);
                    if (result == "Sent new password")
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              "An email has been sent to " + forgetEmail.text)));
                    else
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Entered email does not exist.")));
                  },
                  child: Text("Send email for a new password"),
                )),
          ],
        ),
      ),
    );
  }
}

class CategoryFrequency {
  String name;
  int frequency;

  CategoryFrequency(String name, int frequency) {
    this.name = name;
    this.frequency = frequency;
  }
}

class WelcomeSend extends StatefulWidget {
  final Customer customer;
  final Song song;

  WelcomeSend(this.customer, this.song);

  // void checkConnection() async{
  //   var connectivityResult = await (Connectivity().checkConnectivity());
  //   if (connectivityResult == ConnectivityResult.none)
  //     connected = false;
  // }
  @override
  State<StatefulWidget> createState() {
    //checkConnection();
    playLists = this.customer.playlists.split('*');
    if (playListChange) {
      for (int i = 1; i < playLists.length; i++) {
        List<String> tmp = playLists[i].split('_');
        playlistNames.add(tmp[tmp.length - 1]);
      }
      playlistNames = playlistNames.toSet().toList();
      playListChange = false;
    }
    return Welcome(this.customer, this.song);
  }
}

class Welcome extends State<WelcomeSend> {
  Customer customer;
  Song song;
  Welcome(this.customer, this.song);
  Widget titleWidget;
  final searched = TextEditingController();
  List<String> songNames;
  MusicSend ms;
  String currentPlaylist;
  Future<List<Song>> iterateSongs(int page) async {
    nSongs = new List<Song>.empty(growable: true);
    if(!songsLoaded){
      songs = new List<Song>.empty(growable: true);
      await FirebaseFirestore.instance.collection("Songs").get().then((value) {
        value.docs.forEach((result) {
          songs.add(new Song(
              id: result['id'],
              name: result['name'].toString(),
              artist: result['artist'].toString(),
              urlSong: result['urlMusic'].toString(),
              urlPic: result['urlPicture'].toString(),
              category: result['category'].toString()));
        });
      });
      songsLoaded = true;
    }
    songs.sort((a, b) => a.id.compareTo(b.id));
    if(page == 0 || page == null){
      if (searched.text != "") {
        bool notFound = false;
        String lowerSearched = searched.text.trim().toLowerCase();
        for (int i = 0; i < songs.length; i++) {
          String lowerSongArtist = songs[i].name.trim().toLowerCase();
          for (int j = 0; j < lowerSearched.length; j++) {
            if (lowerSongArtist[j] != lowerSearched[j]) {
              notFound = true;
              break;
            }
          }
          if (!notFound)
            nSongs.add(songs[i]);
          notFound = false;
          lowerSongArtist = songs[i].artist.trim().toLowerCase();
          List<String> artistsAll = lowerSongArtist.split(', ');
          for (int art = 0; art < artistsAll.length; art++) {
            for (int j = 0; j < lowerSearched.length; j++) {
              if (artistsAll[art][j] != lowerSearched[j]) {
                notFound = true;
                break;
              }
            }
            if (!notFound)
              nSongs.add(songs[i]);
            else
              notFound = false;
          }
        }
      }
      else if (customer.history != "") {
        int lastListenedIdx = int.tryParse(customer.history.split('_')[customer.history.split('_').length - 2]);
        List<Song> laterSongs = new List<Song>.empty(growable: true);
        for (int i = 0; i < songs.length; i++) {
          if (songs[i].category == songs[lastListenedIdx].category)
            nSongs.add(songs[i]);
          else
            laterSongs.add(songs[i]);
        }
        for (int i = 0; i < laterSongs.length; i++)
          nSongs.add(laterSongs[i]);
      }
      else
        nSongs = songs;
    }
    else if (page == 1 && customer.liked != "") {
      List<String> likedSongs = customer.liked.split("_");
      int idx;
      for (int i = likedSongs.length - 1; i >= 0; i--) {
        if ((idx = int.tryParse(likedSongs[i])) != null)
          nSongs.add(songs[idx]);
      }
    }
    else if (page == 2 && customer.history != "") {
      List<String> historySongs = customer.history.split("_");
      int idx;
      for (int i = historySongs.length - 1; i >= 0; i--) {
        if ((idx = int.tryParse(historySongs[i])) != null)
          nSongs.add(songs[idx]);
      }
    }
    else if (page == 3) {
      for (int i = filesInDir.length - 1; i >= 0; i--)
        for (int j = 0; j < songs.length; j++) {
          if (filesInDir[i] == directory.path + '/' + songs[j].artist + ' - ' + songs[j].name) {
            nSongs.add(songs[j]);
            break;
          }
        }
    }
    else if(page == 4){
      if (this.customer.liked != "") {
        if ((nSongs = await iterateCustomers()).length < 1){
          List<String> mixSongs = customer.liked.split("_");
          SplayTreeMap catFreq = new SplayTreeMap();
          for (int i = 0; i < mixSongs.length - 1; i++)
            catFreq[songs[int.tryParse(mixSongs[i])].category] =
                0.toString();
          for (int i = 0; i < mixSongs.length - 1; i++)
            catFreq[songs[int.tryParse(mixSongs[i])].category] = (int.tryParse(
                catFreq[songs[int.tryParse(mixSongs[i])].category]) + 1)
                .toString();
          List<CategoryFrequency> cf = new List<CategoryFrequency>.empty(
              growable: true);
          catFreq.forEach((key, value) {
            cf.add(new CategoryFrequency(key, int.tryParse(value)));
          });
          int maxIdx;
          for (int i = 0; i < cf.length; i++) {
            maxIdx = i;
            for (int j = i + 1; j < cf.length; j++)
              if (cf[j].frequency > cf[maxIdx].frequency) maxIdx = j;
            CategoryFrequency temp = cf[i];
            cf[i] = cf[maxIdx];
            cf[maxIdx] = temp;
          }
          for (int j = 0; j < cf.length; j++)
            for (int i = songs.length - 1; i >= 0; i--)
              if (songs[i].category == cf[j].name) {
                nSongs.add(songs[i]);
              }
        }
      }
      else
        nSongs = songs;
    }
    else if (page == 5) {
      for (int i = 0; i < songs.length; i++) {
        List<String> currentArtists =
        songs[i].artist.trim().split(',');
        for (int j = 0; j < currentArtists.length; j++) {
          if (currentArtists[j].compareTo(individualArtist) == 0)
            nSongs.add(songs[i]);
        }
      }
    }
    else if (page == 6 && playLists.length > 0 && currentPlaylist != "") {
      List<String> contentPlaylist;
      for (String singlePlaylist in playLists) {
        List<String> tmpSinglePlaylist = singlePlaylist.split('_');
        if (tmpSinglePlaylist[tmpSinglePlaylist.length - 1] ==
            currentPlaylist) contentPlaylist = tmpSinglePlaylist;
      }
      for (int i = 1; i < contentPlaylist.length - 1; i++)
        nSongs.add(songs[int.tryParse(contentPlaylist[i])]);
    }
    return nSongs;
  }
  Future<List<Song>> iterateCustomers() async {
    List<Song> retSongs = new List.empty(growable: true);
    await FirebaseFirestore.instance.collection("Customers").get().then((value) {
      value.docs.forEach((result) {
        bool skip = false;
        List<Object> keys = result.data().keys.toList();
        List<Object> values = result.data().values.toList();
        List<String> thisLiked = this.customer.liked.split('_');
        List<String> otherLiked = new List<String>.empty(growable: true);
        for (int idx = 0; idx < keys.length; idx++) {
          if (keys[idx] == 'email' && values[idx].toString().compareTo(this.customer.email) == 0) {
            skip = true;
            break;
          }
          if (keys[idx] == 'liked')
            otherLiked = values[idx].toString().split('_');
        }
        if (!skip) {
          int equal = 0;
          bool copyOther = false;
          for (int i = 0; i < thisLiked.length; i++) {
            for (int j = 0; j < otherLiked.length; j++)
              if (thisLiked[i] == otherLiked[j]) {
                equal++;
                if (equal > thisLiked.length / 2) {
                  copyOther = true;
                  break;
                }
              }
            if (copyOther) {
              bool duplicate = false;
              for (String otherValue in otherLiked) {
                for (String thisValue in thisLiked) {
                  if (thisValue == otherValue) {
                    duplicate = true;
                    break;
                  }
                }
                if (!duplicate)
                  retSongs.add(songs[int.tryParse(otherValue)]);
                else
                  duplicate = false;
              }
              break;
            }
          }
        }
        else
          skip = false;
      });
    });
    return retSongs;
  }

  @override
  Widget build(BuildContext context) {
    ms = new MusicSend(this.customer, this.song);
    setState(() {
      if (page == 0 || page == null) {
        titleWidget = TextField(
            controller: searched,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
                hintStyle: TextStyle(color: Colors.white),
                hintText: "Enter a song or artist to search..."));
      } else if (page == 1)
        titleWidget = Text('Liked Songs');
      else if (page == 2)
        titleWidget = Text('History');
      else if (page == 3)
        titleWidget = Text('Downloaded Songs');
      else if (page == 4)
        titleWidget = Text('Your Mix');
      else if (page == 5)
        titleWidget = Text("Songs ft. " + individualArtist);
      else if (page == 6) {
        if (currentPlaylist == null) {
          if (playlistNames.length > 0)
            currentPlaylist = playlistNames[0];
          else
            currentPlaylist = "";
        }
        titleWidget = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButton(
              dropdownColor: color,
              items: playlistNames.map((String value) {
                return new DropdownMenuItem<String>(
                  value: value,
                  child: new Text(
                    value,
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (String value) {
                setState(() {
                  currentPlaylist = value;
                });
              },
              value: currentPlaylist,
            ),
            ElevatedButton(
                onPressed: () {
                  final playlistName = TextEditingController();
                  return showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: Text("Enter playlist's name"),
                        content: TextField(controller: playlistName),
                        actions: [
                          ElevatedButton(
                            child: Text('No'),
                            onPressed: () => Navigator.pop(c, false),
                          ),
                          ElevatedButton(
                            child: Text('Yes'),
                            onPressed: () {
                              if(playlistName.text != "") {
                                Navigator.pop(c, false);
                                this.customer.playlists +=
                                    '*_' + playlistName.text;
                                d.updateCustomerPlaylist(
                                    customer, customer.playlists);
                                playLists =
                                    this.customer.playlists.split('*');
                                playListChange = true;
                                page = 0;
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) =>
                                        WelcomeSend(this.customer, this.song)));
                              }
                              else
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter a name.")));
                            },
                          ),
                        ],
                      ));
                },
                child: Text("Create")),
            ElevatedButton(
                onPressed: () {
                  int cnt = 0;
                  for (String find in playlistNames) {
                    cnt++;
                    if (find == currentPlaylist) break;
                  }
                  List<String> tmpPlayLists = new List.empty(growable: true);
                  this.customer.playlists = "";
                  playlistNames = new List<String>.empty(growable: true);
                  for (int r = 0; r < playLists.length; r++) {
                    if (r == cnt) continue;
                    tmpPlayLists.add(playLists[r]);
                    if (playLists[r] != "")
                      this.customer.playlists += '*' + playLists[r];
                  }
                  playLists = tmpPlayLists;
                  d.updateCustomerPlaylist(customer, customer.playlists);
                  for (int i = 1; i < playLists.length; i++) {
                    List<String> tmp = playLists[i].split('_');
                    playlistNames.add(tmp[tmp.length - 1]);
                  }
                  playlistNames = playlistNames.toSet().toList();
                  page = 0;
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) =>
                          WelcomeSend(this.customer, this.song)));
                },
                child: Text("Delete"))
          ],
        );
      }
    });
    return WillPopScope(
      onWillPop: () {
        if (page == 0 || page == null)
          return showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
              title: Text('Warning'),
              content: Text('Do you really want to sign out?'),
              actions: [
                ElevatedButton(
                  child: Text('No'),
                  onPressed: () => Navigator.pop(c, false),
                ),
                ElevatedButton(
                  child: Text('Yes'),
                  onPressed: () {
                    ms.stopAudio();
                    context.read<AuthenticationServices>().signOut();
                    Navigator.pop(c, false);
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => Login()));
                  },
                ),
              ],
            ),
          );
        else {
          return showDialog(
              context: context,
              builder: (context) {
                page = 0;
                Navigator.pop(context, true);
                return WelcomeSend(this.customer, this.song);
              });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: color,
          title: titleWidget,
          centerTitle: true,
        ),
        floatingActionButton: Opacity(
          opacity: 0.6,
          child: Container(
            width: MediaQuery.of(context).size.width - 200,
            // height: 75,
            child: FloatingActionButton(
              backgroundColor: color,
              isExtended: true,
              child: Text(
                currentPlaying == null ? "..." : currentPlaying.name,
                textAlign: TextAlign.center,
              ),
              onPressed: () {
                if (currentPlaying != null)
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) =>
                          MusicSend(customer, currentPlaying)));
              },
            ),
          ),
        ),
        drawer: Drawer(
          child: Container(
            color: color,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                    child: Image(
                      image: AssetImage('assets/Background.jpg'),
                      fit: BoxFit.fill,
                    )),
                ListTile(
                  title: Text(
                    'Home',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  onTap: () {
                    page = 0;
                    setState(() {
                      titleWidget = Text("Home");
                    });
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => WelcomeSend(this.customer, this.song)));
                  },
                ),
                ListTile(
                  title: Text(
                    "Liked Songs",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  onTap: () {
                    page = 1;
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) =>
                            WelcomeSend(this.customer, this.song)));
                  },
                ),
                ListTile(
                  title: Text(
                    "Your Mix",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  onTap: () {
                    page = 4;
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => WelcomeSend(this.customer, this.song)));
                  },
                ),
                ListTile(
                  title: Text(
                    "History",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  onTap: () {
                    page = 2;
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) =>
                            WelcomeSend(this.customer, this.song)));
                  },
                ),
                ListTile(
                  title: Text(
                    "Playlists",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  onTap: () {
                    page = 6;
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) =>
                            WelcomeSend(this.customer, this.song)));
                  },
                ),
                ListTile(
                  title: Text(
                    "Downloads",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  onTap: () {
                    page = 3;
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) =>
                            WelcomeSend(this.customer, this.song)));
                  },
                ),
                ListTile(
                  title: Text("Account Settings",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => AccountSend(this.customer, this.song)));
                  },
                ),
                ListTile(
                    title: Text(
                      'Sign Out',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, color: Colors.white),
                    ),
                    onTap: () {
                      showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: Text('Warning'),
                          content: Text('Do you really want to sign out?'),
                          actions: [
                            ElevatedButton(
                              child: Text('No'),
                              onPressed: () => Navigator.pop(c, false),
                            ),
                            ElevatedButton(
                              child: Text('Yes'),
                              onPressed: () {
                                ms.stopAudio();
                                context.read<AuthenticationServices>().signOut();
                                Navigator.pop(c, false);
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => Login()));
                              },
                            ),
                          ],
                        ),
                      );
                    }),
              ],
            ),
          ),
        ),
        body: FutureBuilder(
          future: iterateSongs(page),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if(!snapshot.hasData)
              return Center(
                child: CircularProgressIndicator(backgroundColor: color,),
              );
            List<Song> songs = snapshot.data;
            if(songs.length < 1)
              return Container(
                alignment: Alignment.center,
                child: Text("No songs found."),
              );
            return ListView.builder(
              itemCount: songs.length,
              itemBuilder: (BuildContext context, int index) {
                copyNSong = songs;
                return Container(
                  foregroundDecoration: BoxDecoration(),
                  height: 200,
                  decoration: BoxDecoration(
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: NetworkImage(songs[index].urlPic),
                      )),
                  child: ListTile(
                    title: Text(
                      songs[index].artist + ' - ' + songs[index].name ,
                      style: TextStyle(
                        color: Colors.black,
                        shadows: <Shadow>[
                          Shadow(
                            offset: Offset(0.0, 0.0),
                            blurRadius: 3.0,
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
                          Shadow(
                            offset: Offset(0.0, 0.0),
                            blurRadius: 3.0,
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
                        ],
                      ),
                      softWrap: true,
                      textAlign: TextAlign.center,
                    ),
                    onTap: () async{
                      if (previousMusic != null) {
                        if (currentPlaying != null &&
                            songs[index].name != currentPlaying.name) {
                          MusicSend ms =
                          new MusicSend(this.customer, currentPlaying);
                          ms.stopAudio();
                        }
                        previousMusic.disposed = true;
                        previousMusic.dispose();
                      }
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) =>
                              MusicSend(customer, songs[index])));
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class AccountSend extends StatefulWidget {
  final Customer customer;
  Song song;
  AccountSend(this.customer, this.song);

  @override
  State<StatefulWidget> createState() {
    return Account(this.customer, this.song);
  }
}

class Account extends State<AccountSend> {
  Customer customer;
  Song song;
  MusicSend ms;
  Account(this.customer, this.song);

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: AppBar(
          backgroundColor: color,
          title: Text(this.customer.name + "\'s Account Settings"),
          centerTitle: true,
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    style: ElevatedButton.styleFrom(primary: color),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => UpdateSend(this.customer)));
                    },
                    child: Text("Update Account")),
              ],
            ),
            ElevatedButton(
                style: ElevatedButton.styleFrom(primary: color),
                onPressed: () {
                  showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: Text("Warning"),
                        content: Text(
                            "Do you really want to delete this account?"),
                        actions: [
                          ElevatedButton(
                              onPressed: () => Navigator.pop(c, false),
                              child: Text("No")),
                          ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(c, false);
                                ms = new MusicSend(customer, song);
                                ms.stopAudio();
                                d.deleteCustomer(customer);
                                Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (context) => Login()));
                                await context
                                    .read<AuthenticationServices>()
                                    .delete(
                                  email: customer.email,
                                  password: customer.password,
                                );
                              },
                              child: Text("Yes")),
                        ],
                      ));
                },
                child: Text("Delete Account")),
          ],
        ));
  }
}

//List<YT_API> ytResult;
bool exists;
int length;
bool toggle = false;
Icon icon = Icon(Icons.play_circle_fill_outlined);
Duration totalDuration = new Duration();
Duration currentDuration = new Duration();
String audioState = "";
double range = 0;

class MusicSend extends StatefulWidget {
  final Customer customer;
  final Song song;
  MusicSend(this.customer, this.song);

  playAudio(String path) async {
    currentPlaying = this.song;
    if (exists)
      ap.play(path, isLocal: true);
    else
      ap.play(path);
    toggle = true;
    icon = Icon(Icons.pause_circle_filled_outlined);
  }

  pauseAudio() {
    ap.pause();
    toggle = false;
    icon = Icon(Icons.play_circle_fill_outlined);
  }

  stopAudio() {
    ap.stop();
    toggle = false;
    icon = Icon(Icons.play_circle_fill_outlined);
    currentDuration = Duration.zero;
    currentPlaying = null;
    range = 0;
  }

  void addHistory(Song sng) {
    List<String> historySongs;
    this.customer.history += sng.id.toString() + "_";
    historySongs = this.customer.history.split("_");
    String newHistory = "";
    for (int i = 0; i < historySongs.length; i++)
      if (historySongs[i] != "" && int.tryParse(historySongs[i]) != sng.id)
        newHistory += historySongs[i] + "_";
    newHistory += sng.id.toString() + "_";
    this.customer.history = newHistory;
    d.updateCustomerHistory(customer, this.customer.history);
  }

  void checkExists(Song checkSong) {
    exists = false;
    String checkSongPath = checkSong.artist + ' - ' + checkSong.name;
    String dir = directory.path + "/" + checkSongPath;
    exists = Directory(dir).existsSync();
    if (exists) {
      toPlay = dir + '/' + checkSongPath + '.mp3';
      //pictureLocation = dir + '/' + checkSong.name + '.jpg';
    } else {
      toPlay = checkSong.urlSong;
      //pictureLocation = checkSong.urlPic;
    }
  }

  @override
  State<StatefulWidget> createState() {
    back = false;
    checkExists(this.song);
    return Music(this.customer, song);
  }
}

class Music extends State<MusicSend> {
  Customer customer;
  Song song;
  MusicSend ms;
  Color likeColor, loopColor, shuffleColor;
  String title;
  bool disposed = false;

  Music(this.customer, this.song);

  @override
  void initState() {
    ms = new MusicSend(customer, song);
    ms.playAudio(song.urlSong);
    ms.addHistory(this.song);
    initAudio();
    previousMusic = this;
    super.initState();
  }

  initAudio() {
    if (!back) {
      ap.onDurationChanged.listen((event) {
        if (ms != null && !this.disposed)
          setState(() {
            totalDuration = event;
          });
      });
      ap.onAudioPositionChanged.listen((event) {
        if (ms != null && !this.disposed)
          setState(() {
            currentDuration = event;
            range = currentDuration.inSeconds.toDouble();
          });
      });
      ap.onPlayerStateChanged.listen((event) {
        if (!this.disposed)
          setState(() {
            if (event == AudioPlayerState.PAUSED) audioState = "Paused";
            if (event == AudioPlayerState.PLAYING) {
              audioState = "Playing";
              moveSong = true;
              if (shutChecked && !beingUsed)
                Future.delayed(const Duration(minutes: 10), () {
                  print("Closing");
                  exit(0);
                });
            }
            if (event == AudioPlayerState.COMPLETED) {
              audioState = "Over";
              beingUsed = false;
              if (moveSong) {
                if (loopToggle)
                  ms.playAudio(toPlay);
                else if (shuffleToggle) {
                  int rand = new Random().nextInt(copyNSong.length - 1);
                  currentPlaying = copyNSong[rand];
                  this.song = currentPlaying;
                  ms = new MusicSend(customer, this.song);
                  ms.checkExists(this.song);
                  ms.playAudio(toPlay);
                  ms.addHistory(this.song);
                } else {
                  for (int i = 0; i < copyNSong.length; i++) {
                    if (copyNSong[i].id == currentPlaying.id) {
                      if (i != copyNSong.length - 1)
                        currentPlaying = copyNSong[i + 1];
                      else
                        currentPlaying = copyNSong[0];
                      this.song = currentPlaying;
                      break;
                    }
                  }
                  ms = new MusicSend(customer, this.song);
                  ms.checkExists(this.song);
                  ms.playAudio(toPlay);
                  ms.addHistory(this.song);
                }
                moveSong = false;
              }
            }
            if (event == AudioPlayerState.STOPPED) audioState = "Stopped";
          });
      });
    }
  }

  String findDuration(Duration duration) {
    int minutes = duration.inSeconds ~/ 60;
    int seconds = duration.inSeconds - minutes * 60;
    return minutes.toInt().toString() + ":" + seconds.toInt().toString();
  }

  void readFiles() async {
    filesInDir.clear();
    filesInDir = new List<String>.empty(growable: true);
    await for (var file
    in directory.list(recursive: false, followLinks: false)) {
      filesInDir.add(file.path);
    }
  }

  String reverse(String str) {
    String nStr = "";
    for (int i = str.length - 1; i >= 0; i--) nStr += str[i];
    return nStr;
  }

  List<Widget> createChildren(List<String> artists, BuildContext context) {
    return new List<Widget>.generate(artists.length, (int index) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(primary: color),
        onPressed: () {
          page = 5;
          individualArtist = artists[index];
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => WelcomeSend(customer, this.song)));
        },
        child: Text(artists[index].toString()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    title = this.song.artist + " - " + this.song.name;
    bool isThere = false;
    List<String> likedSongs;
    if (this.customer.liked != "") {
      likedSongs = customer.liked.split("_");
      for (int i = 0; i < likedSongs.length; i++)
        if (likedSongs[i] != null &&
            int.tryParse(likedSongs[i]) == this.song.id) {
          likeColor = Colors.blue;
          isThere = true;
          break;
        }
    } else
      this.customer.liked = "";
    List<String> artists =
    this.song.artist.trim().split(','); //split(this.song.artist, ',');
    return WillPopScope(
      onWillPop: () async {
        readFiles();
        back = true;
        // this.deactivate();
        // this.dispose();
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => WelcomeSend(customer, this.song)));
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: color,
          title: FittedBox(fit: BoxFit.fitWidth, child: Text('$title')),
          centerTitle: true,
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: createChildren(artists, context),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  this.song.urlPic,
                  width: 200,
                  height: 200,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () {
                    if (!isThere) {
                      this.customer.liked += this.song.id.toString() + "_";
                      d.updateCustomerLiked(this.customer, this.customer.liked);
                      setState(() {
                        likeColor = Colors.blue;
                      });
                    } else {
                      String newLiked = "";
                      for (int i = 0; i < likedSongs.length; i++)
                        if (likedSongs[i] != "" &&
                            int.tryParse(likedSongs[i]) != this.song.id)
                          newLiked += likedSongs[i] + "_";
                      this.customer.liked = newLiked;
                      d.updateCustomerLiked(this.customer, newLiked);
                      setState(() {
                        likeColor = Colors.black;
                      });
                    }
                  },
                  icon: Icon(Icons.thumb_up),
                  color: likeColor,
                ),
                IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      String selectedPlaylist;
                      if (selectedPlaylist == null && playlistNames.length > 0)
                        selectedPlaylist = playlistNames.first;
                      return showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: Text("Select a playlist"),
                            content: StatefulBuilder(
                              builder: (BuildContext context,
                                  void Function(void Function()) setState) {
                                return DropdownButton(
                                  value: selectedPlaylist,
                                  items: playlistNames
                                      .map((String item) =>
                                  new DropdownMenuItem<String>(
                                      value: item,
                                      child: new Text(item)))
                                      .toList(),
                                  onChanged: (String value) {
                                    setState(() {
                                      selectedPlaylist = value;
                                    });
                                  },
                                );
                              },
                            ),
                            actions: [
                              ElevatedButton(
                                child: Text('Cancel'),
                                onPressed: () => Navigator.pop(c, false),
                              ),
                              ElevatedButton(
                                child: Text('Add to the playlist'),
                                onPressed: () {
                                  Navigator.pop(c, false);
                                  playLists =
                                      this.customer.playlists.split('*');
                                  int cntIdx = 0;
                                  for (String pList in playlistNames) {
                                    if (pList == selectedPlaylist) break;
                                    cntIdx++;
                                  }
                                  int cntPlaylists = 0;
                                  String tmpPlaylist = "";
                                  for (int i = 0;
                                  i < this.customer.playlists.length;
                                  i++) {
                                    if (this.customer.playlists[i] == '*') {
                                      if (cntPlaylists == cntIdx) {
                                        List<String> tmpUnique =
                                        playLists[cntPlaylists + 1]
                                            .split('_');
                                        for (int j = 1;
                                        j < tmpUnique.length - 1;
                                        j++) {
                                          if (int.tryParse(tmpUnique[j]) ==
                                              this.song.id) {
                                            return;
                                          }
                                        }
                                        tmpPlaylist +=
                                            this.customer.playlists[i] +
                                                '_' +
                                                this.song.id.toString();
                                        cntPlaylists++;
                                        continue;
                                      }
                                      cntPlaylists++;
                                    }
                                    tmpPlaylist +=
                                    this.customer.playlists[i];
                                  }
                                  this.customer.playlists = tmpPlaylist;
                                  d.updateCustomerPlaylist(
                                      customer, customer.playlists);
                                  playListChange = true;
                                },
                              ),
                            ],
                          ));
                    }),
                IconButton(
                  icon: Icon(Icons.download_rounded),
                  onPressed: () async {
                    if (await Permission.storage.request().isDenied) return;
                    if (!exists) {
                      String folderToDownload =
                          this.song.artist + ' - ' + this.song.name;
                      final path =
                      Directory(directory.path + '/' + folderToDownload);
                      path.create();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content:
                          Text("Started downloading " + folderToDownload)));
                      await FlutterDownloader.enqueue(
                        fileName: folderToDownload + '.mp3',
                        url: this.song.urlSong,
                        savedDir: directory.path + '/' + folderToDownload,
                      );
                      exists = true;
                    } else {
                      showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: Text('Warning'),
                          content:
                          Text('Do you really want to delete this song?'),
                          actions: [
                            ElevatedButton(
                              child: Text('No'),
                              onPressed: () => Navigator.pop(c, false),
                            ),
                            ElevatedButton(
                              child: Text('Yes'),
                              onPressed: () {
                                String pathToDelete =
                                    this.song.artist + ' - ' + this.song.name;
                                Directory(directory.path + '/' + pathToDelete)
                                    .deleteSync(recursive: true);
                                readFiles();
                                ms.stopAudio();
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) =>
                                        WelcomeSend(customer, this.song)));
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(pathToDelete +
                                            " has been deleted.")));
                              },
                            ),
                          ],
                        ),
                      );
                    }
                  },
                )
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(findDuration(currentDuration)),
                IconButton(
                    icon: Icon(Icons.loop),
                    color: loopColor,
                    onPressed: () {
                      setState(() {
                        if (loopToggle) {
                          loopColor = Colors.black;
                          loopToggle = false;
                        } else {
                          loopColor = Colors.blue;
                          shuffleColor = Colors.black;
                          shuffleToggle = false;
                          loopToggle = true;
                        }
                      });
                    }),
                IconButton(
                    icon: Icon(Icons.shuffle),
                    color: shuffleColor,
                    onPressed: () {
                      setState(() {
                        if (shuffleToggle) {
                          shuffleColor = Colors.black;
                          shuffleToggle = false;
                        } else {
                          shuffleColor = Colors.blue;
                          loopColor = Colors.black;
                          loopToggle = false;
                          shuffleToggle = true;
                        }
                      });
                    }),
                Text(findDuration(totalDuration)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 300,
                  child: SliderTheme(
                    data: SliderThemeData(
                      thumbColor: color,
                      activeTrackColor: color,
                    ),
                    child: Slider(
                      value: range,
                      min: 0,
                      max: totalDuration.inSeconds.toDouble(),
                      onChanged: (newRange) {
                        setState(() {
                          ap.seek(new Duration(seconds: newRange.toInt()));
                          range = newRange;
                        });
                      },
                    ),
                  ),
                )
              ],
            ),
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () {
                      ms.stopAudio();
                      if (currentPlaying != null)
                        for (int i = 0; i < copyNSong.length; i++) {
                          if (copyNSong[i].id == currentPlaying.id) {
                            if (i != 0) {
                              currentPlaying = copyNSong[i - 1];
                            } else
                              currentPlaying = copyNSong[copyNSong.length - 1];

                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) =>
                                    MusicSend(customer, currentPlaying)));
                            break;
                          }
                        }
                      else
                        for (int i = 0; i < copyNSong.length; i++) {
                          if (copyNSong[i].id == this.song.id) {
                            if (i != 0) {
                              currentPlaying = copyNSong[i - 1];
                            } else
                              currentPlaying = copyNSong[copyNSong.length - 1];
                            previousMusic.disposed = true;
                            previousMusic.dispose();
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) =>
                                    MusicSend(customer, currentPlaying)));
                            break;
                          }
                        }
                    },
                    icon: Icon(Icons.fast_rewind),
                    iconSize: 84,
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (toggle)
                          ms.pauseAudio();
                        else {
                          ms.playAudio(toPlay);
                        }
                        beingUsed = true;
                      });
                    },
                    icon: icon,
                    iconSize: 128,
                  ),
                  IconButton(
                    onPressed: () {
                      ms.stopAudio();
                      if (currentPlaying != null)
                        for (int i = 0; i < copyNSong.length; i++) {
                          if (copyNSong[i].id == currentPlaying.id) {
                            if (i != copyNSong.length - 1) {
                              currentPlaying = copyNSong[i + 1];
                            } else
                              currentPlaying = copyNSong[0];
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) =>
                                    MusicSend(customer, currentPlaying)));
                            break;
                          }
                        }
                      else
                        for (int i = 0; i < copyNSong.length; i++) {
                          if (copyNSong[i].id == this.song.id) {
                            if (i != copyNSong.length - 1) {
                              currentPlaying = copyNSong[i + 1];
                            } else
                              currentPlaying = copyNSong[0];
                            this.deactivate();
                            previousMusic.disposed = true;
                            previousMusic.dispose();
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) =>
                                    MusicSend(customer, currentPlaying)));
                            break;
                          }
                        }
                    },
                    icon: Icon(Icons.fast_forward),
                    iconSize: 84,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UpdateSend extends StatefulWidget {
  final Customer customer;

  UpdateSend(this.customer);

  @override
  State<StatefulWidget> createState() {
    return Update(this.customer);
  }
}

class Update extends State<UpdateSend> {
  Customer customer;
  final updName = TextEditingController();
  final updEmail = TextEditingController();
  final updPass = TextEditingController();

  Update(this.customer);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: color,
        title: Text("Update Account Information"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: updEmail,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: "Enter a new email...",
              ),
            ),
            TextField(
              controller: updName,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: "Enter a new username...",
              ),
            ),
            TextField(
              controller: updPass,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: "Enter a new password...",
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(primary: color),
              onPressed: () async {
                if (updEmail.text != "" && updPass.text != "") {
                  d.deleteCustomer(this.customer);
                  await context.read<AuthenticationServices>().delete(
                      email: this.customer.email,
                      password: this.customer.password);
                  this.customer.email = updEmail.text;
                  this.customer.name = updName.text;
                  this.customer.password = updPass.text;
                  d.createCustomer(this.customer);
                  String result =
                  await context.read<AuthenticationServices>().signUp(
                    email: this.customer.email.trim(),
                    password: this.customer.password.trim(),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Account information has been updated.")));
                } else
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please enter all fields.")));
              },
              child: Text("Update"),
            ),
          ],
        ),
      ),
    );
  }
}
