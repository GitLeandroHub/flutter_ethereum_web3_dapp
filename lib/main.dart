import 'package:flutter/material.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:velocity_x/velocity_x.dart';
import 'slider.dart';
import 'package:flutter/services.dart.';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await DotEnv().load('.env');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: "TreeCoin"),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Client httpClient;
  Web3Client ethClient;
  bool data = false;
  int myAmount = 0;
  var privateKey = DotEnv().env['PRIVATE'];

  final myAddress = "0x25C20f433DC1aD3fF303355ed7209C3BaD968B67";
  String txHash;
  var myData;

  //to fetch the balance
  @override
  void initState() {
    super.initState();
    httpClient = Client();
    ethClient = Web3Client(
        "https://ropsten.infura.io/v3/e2c37a2d4e16430e99a0a05743b03406",
        httpClient);
    getBalance(myAddress);
  }

  //don't really need "internet" bacause uses the contract abi
  Future<DeployedContract> loadContract() async {
    String abi = await rootBundle.loadString("assets/contracts/abi.json");
    String contractAddress = "0x1E61A91F5c9570B81C72119C5247F0E806C22A9E";

    final contract = DeployedContract(ContractAbi.fromJson(abi, "TreeCoin"),
        EthereumAddress.fromHex(contractAddress));

    return contract;
  }

  Future<List<dynamic>> query(String functionName, List<dynamic> args) async {
    //takes the contract by using the abi
    final contract = await loadContract();
    final ethFunction = contract.function(functionName);
    final result = await ethClient.call(
        contract: contract, function: ethFunction, params: args);

    return result;
  }

  //particular method for fetching the balance
  Future<void> getBalance(String targetAddress) async {
    //EthereumAddress address = EthereumAddress.fromHex(targetAddress);
    List<dynamic> result = await query("getBalance", []);

    myData = result[0];
    data = true;
    setState(() {});
  }

  Future<String> submit(String functionName, List<dynamic> args) async {
    EthPrivateKey credentials = EthPrivateKey.fromHex(privateKey);

    DeployedContract contract = await loadContract();
    final ethFunction = contract.function(functionName);
    final result = await ethClient.sendTransaction(
        credentials,
        Transaction.callContract(
            contract: contract, function: ethFunction, parameters: args),
        chainId: 3);
    return result;
  }

  //create a method to withdraw too
  Future<String> sendCoin() async {
    var bigAmount = BigInt.from(myAmount);

    var response = await submit("depositBalance", [bigAmount]);

    print("Deposited");
    txHash = response;
    setState(() {});
    return response;
  }

  Future<String> withdrawCoin() async {
    var bigAmount = BigInt.from(myAmount);

    var response = await submit("withdrawBalance", [bigAmount]);

    print("Withdraw");
    txHash = response;
    setState(() {});
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vx.gray300,
      body: ZStack([
        VxBox()
            .blue600
            .size(context.screenWidth, context.percentHeight * 30)
            .make(),
        VStack([
          (context.percentHeight * 10).heightBox,
          "Tree Coin".text.xl4.white.bold.center.makeCentered().py16(),
          (context.percentHeight * 5).heightBox,
          VxBox(
                  child: VStack([
            "Balance".text.gray700.xl2.semiBold.makeCentered(),
            10.heightBox,
            data
                ? "\$$myData".text.bold.xl6.makeCentered().shimmer()
                : CircularProgressIndicator().centered()
          ]))
              .p16
              .white
              .size(context.screenWidth, context.percentHeight * 18)
              .rounded
              .shadowXl
              .make()
              .p16(),
          30.heightBox,
          SliderWidget(
              min: 0,
              max: 100,
              finalVal: (value) {
                myAmount = (value * 100).round();
                print(myAmount);
              }).centered(),
          HStack(
            [
              TextButton.icon(
                onPressed: () => getBalance(myAddress),
                style: TextButton.styleFrom(
                  primary: Colors.blue,
                  backgroundColor: Colors.blue,
                  shape: Vx.roundedSm,
                ),
                icon: Icon(
                  Icons.refresh,
                  color: Colors.white,
                ),
                label: "Refresh".text.white.make(),
              ).h(50),
              TextButton.icon(
                onPressed: () => sendCoin(),
                style: TextButton.styleFrom(
                  primary: Colors.green,
                  backgroundColor: Colors.green,
                  shape: Vx.roundedSm,
                ),
                icon: Icon(
                  Icons.call_made_outlined,
                  color: Colors.white,
                ),
                label: "Deposit".text.white.make(),
              ).h(50),
              TextButton.icon(
                onPressed: () => withdrawCoin(),
                style: TextButton.styleFrom(
                  primary: Colors.red,
                  backgroundColor: Colors.red,
                  shape: Vx.roundedSm,
                ),
                icon: Icon(
                  Icons.call_received_outlined,
                  color: Colors.white,
                ),
                label: "Withdraw".text.white.make(),
              ).h(50),
            ],
            alignment: MainAxisAlignment.spaceAround,
            axisSize: MainAxisSize.max,
          ).p16(),
          if (txHash != null) txHash.text.black.makeCentered().p16()
        ])
      ]),
    );
  }
}
