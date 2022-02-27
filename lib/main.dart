import 'dart:convert';
import 'dart:io';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:flutter/material.dart';
import 'package:pixabay_picker/model/pixabay_media.dart';

void main() => runApp(MyApp());

/// To do
class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      home: MyHomePage(),
    );
  }
}

/// To do
class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String keyWord = "";
  String _keyWord = "";
  TextEditingController editingController = TextEditingController();
  List<ImageURL> list_url = [];
  ImageURLDataSource imageURLDataSource;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage("assets/images/image0.png"),
              fit: BoxFit.cover)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Demo'),
          centerTitle: true,
        ),
        body: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                style: const TextStyle(color: Colors.deepOrange, fontSize: 20),
                decoration: InputDecoration(
                  hintText: "Search images",
                  prefixIcon: IconButton(
                      icon: Row(
                        children: const <Widget>[
                          Icon(
                            Icons.search,
                            color: Colors.deepOrange,
                          ),
                        ],
                      ),
                      onPressed: () {
                        _keyWord = keyWord;
                        reBuild();
                      }),
                ),
                onEditingComplete: () {
                  editingController.text = "";
                },
                onChanged: (value) {
                  keyWord = value;
                  reBuild();
                },
                controller: editingController,
              ),
            ),
            FutureBuilder(
              future: getData(_keyWord),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  list_url = [];
                  List<dynamic> data = snapshot.data;
                  for (int i = 0; i < data.length; i++) {
                    list_url.add(ImageURL(snapshot.data[i].previewURL));
                  }
                  return Expanded(
                    child: SfDataGrid(
                        rowHeight: 300,
                        onCellTap:
                            (DataGridCellTapDetails dataGridCellTapDetails) {
                          int rowIndex =
                              dataGridCellTapDetails.rowColumnIndex.rowIndex -
                                  1;
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      ViewImage(list_url[rowIndex].url)));
                        },
                        source: ImageURLDataSource(data: list_url),
                        headerRowHeight: 0,
                        loadMoreViewBuilder:
                            (BuildContext context, LoadMoreRows loadMoreRows) {
                          Future<String> loadRows() async {
                            // Call the loadMoreRows function to call the
                            // DataGridSource.handleLoadMoreRows method. So, additional
                            // rows can be added from handleLoadMoreRows method.
                            await loadMoreRows();
                            return Future<String>.value('Completed');
                          }

                          return FutureBuilder<String>(
                              initialData: 'loading',
                              future: loadRows(),
                              builder: (context, snapShot) {
                                if (snapShot.data == 'loading') {
                                  return Container(
                                      height: 60.0,
                                      width: double.infinity,
                                      decoration: const BoxDecoration(
                                          color: Colors.white,
                                          border: BorderDirectional(
                                              top: BorderSide(
                                                  width: 1.0,
                                                  color: Color.fromRGBO(
                                                      0, 0, 0, 0.26)))),
                                      alignment: Alignment.center,
                                      child: const CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation(
                                              Colors.deepPurple)));
                                } else {
                                  return SizedBox.fromSize(size: Size.zero);
                                }
                              });
                        },
                        columns: [
                          GridColumn(
                              columnName: 'url',
                              width: MediaQuery.of(context).size.width,
                              label: Container(
                                  padding: const EdgeInsets.all(8.0),
                                  alignment: Alignment.center,
                                  child: const Text('URL'))),
                        ]),
                  );
                } else {
                  return Container();
                }
              },
            )
          ],
        ),
      ),
    );
  }

  void reBuild() {
    setState(() {});
  }

  Future<dynamic> getData(String keyWord) async {
    String url = "https://pixabay.com/api/";
    PixabayResponse pixabayResponse;

    url += "?key=" + ("25874111-5ba2117e3338ad276e2b49cf4");

    url += "&q=" + Uri.encodeFull(keyWord);

    url += "&lang=" + Uri.encodeFull('en');
    var data = keyWord != "" ? await getImages(url) : null;

    if (data != null && data.length > 0) {
      List<PixabayImage> images =
          List<PixabayImage>.generate(data['hits'].length, (index) {
        return PixabayImage.fromJson(data['hits'][index]);
      });

      pixabayResponse = PixabayResponse(
          total: data["total"], totalHits: data["totalHits"], hits: images);
      return pixabayResponse.hits;
    } else {
      return null;
    }
  }

  ///  get avaiable images for a [url] from pixabay
  getImages(String url) async {
    // setup Http Get
    HttpClient httpClient = HttpClient();
    HttpClientRequest request = await httpClient.getUrl(Uri.parse(url));
    HttpClientResponse response = await request.close();
    // Process the response.
    if (response.statusCode == 200) {
      // response: OK
      // decode JSON
      String json = await utf8.decoder.bind(response).join();
      var data = jsonDecode(json);
      return data;
    } else {
      return [];
    }
  }
}

class ImageURL {
  /// Creates the ImageURL class with required details.
  ImageURL(this.url);

  /// URL
  final String url;
}

/// An object to set the images collection data source to the datagrid.
class ImageURLDataSource extends DataGridSource {
  /// Creates the Image data source class with required details.
  ImageURLDataSource({List<ImageURL> data}) {
    _data = data;
    _addMoreRows(_imagesCollection.length, 4);
    buildDataGridRows();
  }

  void buildDataGridRows() {
    dataGridRow = _imagesCollection
        .map<DataGridRow>((e) => DataGridRow(cells: [
              DataGridCell<String>(columnName: 'url', value: e.url),
            ]))
        .toList();
  }

  List<ImageURL> _data = [];
  List<DataGridRow> dataGridRow = [];
  final List<ImageURL> _imagesCollection = [];

  @override
  List<DataGridRow> get rows => dataGridRow;

  @override
  Future<void> handleLoadMoreRows() async {
    await Future.delayed(const Duration(seconds: 5));

    _addMoreRows(_imagesCollection.length, 2);
    buildDataGridRows();
    notifyListeners();
  }

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
        cells: row.getCells().map<Widget>((e) {
      return Card(
        child: Image.network(
          e.value,
          fit: BoxFit.fill,
          repeat: ImageRepeat.noRepeat,
        ),
      );
    }).toList());
  }

  void _addMoreRows(int startIndex, int endIndex) {
    for (int i = startIndex; i <= startIndex + endIndex; i++) {
      _imagesCollection.add(ImageURL(_data[i].url));
    }
  }
}

class ViewImage extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const ViewImage(this.url);
  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image')),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Image.network(
            url,
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            fit: BoxFit.fill,
            repeat: ImageRepeat.noRepeat,
          );
        },
      ),
    );
  }
}
