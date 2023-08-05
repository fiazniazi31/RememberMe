import 'package:flutter/material.dart';
import 'package:jazzcash_flutter/jazzcash_flutter.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Jazzcash Flutter Demo',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: const PaymentPage(),
//     );
//   }
// }

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String paymentStatus = "pending";
  ProductModel productModel = ProductModel("Product 1", "100");
  String integritySalt = "5uzvfhw012";
  String merchantID = "MC58822";
  String merchantPassword = "37b5ddevu6";
  String transactionUrl = "https://webhook.site/cdedea82-199b-40ea-9949-9775da5200e4";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("JazzCash Flutter Example"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Product Name : ${productModel.productName}"),
            Text("Product Price : ${productModel.productPrice}"),
            ElevatedButton(
                onPressed: () {
                  _payViaJazzCash(productModel, context);
                },
                child: const Text("Purchase Now !"))
          ],
        ),
      ),
    );
  }

  Future _payViaJazzCash(ProductModel element, BuildContext c) async {
    // print("clicked on Product ${element.name}");

    try {
      JazzCashFlutter jazzCashFlutter = JazzCashFlutter(
        merchantId: merchantID,
        merchantPassword: merchantPassword,
        integritySalt: integritySalt,
        isSandbox: true,
      );

      DateTime date = DateTime.now();

      JazzCashPaymentDataModelV1 paymentDataModelV1 = JazzCashPaymentDataModelV1(
        ppAmount: '${element.productPrice}',
        ppBillReference: 'refbill${date.year}${date.month}${date.day}${date.hour}${date.millisecond}',
        ppDescription: 'Product details  ${element.productName} - ${element.productPrice}',
        ppMerchantID: merchantID,
        ppPassword: merchantPassword,
        ppReturnURL: transactionUrl,
      );

      jazzCashFlutter.startPayment(paymentDataModelV1: paymentDataModelV1, context: context).then((_response) {
        print("response from jazzcash $_response");

        // _checkIfPaymentSuccessfull(_response, element, context).then((res) {
        //   // res is the response you returned from your return url;
        //   return res;
        // });

        setState(() {});
      });
    } catch (err) {
      print("Error in payment $err");
      // CommonFunctions.CommonToast(
      //   message: "Error in payment $err",
      // );
      return false;
    }
  }
}

class ProductModel {
  String? productName;
  String? productPrice;

  ProductModel(this.productName, this.productPrice);
}
