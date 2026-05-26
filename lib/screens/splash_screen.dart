import &#39;package:flutter/material.dart&#39;;
import &#39;../utils/app_theme.dart&#39;;
class SplashScreen extends StatelessWidget {
const SplashScreen({super.key});
@override
Widget build(BuildContext ctx) =&gt; Scaffold(
backgroundColor: AppColors.primary,
body: const Center(child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(Icons.volunteer_activism,
size:72, color:Colors.white),
SizedBox(height:20),
Text(&#39;DonaEduca&#39;, style:TextStyle(
fontSize:32, fontWeight:FontWeight.bold,
color:Colors.white)),
SizedBox(height:40),
CircularProgressIndicator(color:AppColors.accent),
],
)),
);
}