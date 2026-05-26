import &#39;package:flutter/material.dart&#39;;
import &#39;package:firebase_core/firebase_core.dart&#39;;
import &#39;package:firebase_auth/firebase_auth.dart&#39;;
import &#39;utils/app_theme.dart&#39;;
import &#39;screens/splash_screen.dart&#39;;
import &#39;screens/login_screen.dart&#39;;
import &#39;screens/home_wrapper.dart&#39;;
void main() async {
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp();
runApp(const DonaEducaApp());
}
class DonaEducaApp extends StatelessWidget {
const DonaEducaApp({super.key});
@override
Widget build(BuildContext ctx) =&gt; MaterialApp(
title: &#39;DonaEduca&#39;,
debugShowCheckedModeBanner: false,
theme: AppTheme.theme,
home: StreamBuilder&lt;User?&gt;(
stream: FirebaseAuth.instance.authStateChanges(),
builder: (ctx, snap) {

if (snap.connectionState == ConnectionState.waiting)
return const SplashScreen();
return snap.hasData
? const HomeWrapper()
: const LoginScreen();
},
),
);
}