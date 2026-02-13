import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';



class Iconsvg extends StatefulWidget {
  String ? link;
  double heigth;
  double width;
  Color color;

  Iconsvg({super.key,this.link,this.color = Colors.black,this.heigth =15,this.width= 15});

  @override
  State<Iconsvg> createState() => _IconsvgState();
}

class _IconsvgState extends State<Iconsvg> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // UserModels.getusers();
    // InfoModel.getinfousers();
  }


  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
        widget.link!,
        color: widget.color,
        height: widget.heigth,
        width: widget.width,

        semanticsLabel: 'A red up arrow'
    );
  }
}
