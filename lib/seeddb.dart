import 'package:flutter/material.dart';

class AssignAssetsToCrew extends StatefulWidget {
  const AssignAssetsToCrew({super.key});

  @override
  State<AssignAssetsToCrew> createState() => _AssignAssetsToCrewState();
}

class _AssignAssetsToCrewState extends State<AssignAssetsToCrew> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Assign Assets to crew")),
      body: SafeArea(
        child: Column(
          children: [
            Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),

                child: FormField(
                  builder: (field) {
                    return Text('Need staff details to assign asset');
                  },
                ),
              ),
            ),

            GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
              ),
              itemBuilder: (context, index) {

                return ListView.builder(
                  itemBuilder: (context, index) {
                    Text("Select Asset to assign to crew");
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
