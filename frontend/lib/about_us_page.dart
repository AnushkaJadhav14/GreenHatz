import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsPage extends StatelessWidget {
  final String corporateId;

  const AboutUsPage({Key? key, required this.corporateId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FadeInDown(
              duration: Duration(milliseconds: 800),
              child: Text(
                'About Green HatZ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: FadeInUp(
              duration: Duration(milliseconds: 1000),
              child: Text(
                'Empowering Excellence, Inspiring Innovation',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
          SizedBox(height: 20),

          // Company Overview
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: FadeInLeft(
              duration: Duration(milliseconds: 1200),
              child: Container(
                padding: EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Who We Are',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Green HatZ is a dynamic platform dedicated to fostering creativity and collaboration. Founded with the vision of empowering individuals and teams to turn their ideas into reality, we provide a space where innovation thrives. Our community is built on the principles of openness, imagination, and collective growth.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Project Mission
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: FadeInRight(
              duration: Duration(milliseconds: 1400),
              child: Container(
                padding: EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Our Mission',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Our mission is to inspire and support a global network of innovators. By providing tools, resources, and a collaborative environment, we aim to transform creative ideas into impactful solutions that benefit both individuals and organizations.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Committee Members Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                BounceInDown(
                  duration: Duration(milliseconds: 1600),
                  child: Text(
                    'Committee Members',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Wrap(
                  spacing: 20.0,
                  runSpacing: 20.0,
                  alignment: WrapAlignment.center,
                  children: [
                    _teamMemberCard(
                      context,
                      'assets/about_Us_Images/Sharad_sir.jpeg',
                      'Sharad Jambukar',
                      'PROJECT SPONSOR',
                      'https://www.linkedin.com/in/sharadjambukar?utm_source=share&utm_campaign=share_via&utm_content=profile&utm_medium=android_app',
                    ),
                    _teamMemberCard(
                      context,
                      'assets/about_Us_Images/Kumarsan_sir.JPG',
                      'C Kumaresan',
                      'PROJECT CHAMPION',
                      'https://www.linkedin.com/in/kumaresan-c-abbb6912/?originalSubdomain=in',
                    ),
                    _teamMemberCard(
                      context,
                      'assets/about_Us_Images/Prakash_sir.JPG',
                      'Prakash Shukla',
                      'PROJECT LEAD',
                      'https://www.linkedin.com/in/prakash-shukla-a69688128?utm_source=share&utm_campaign=share_via&utm_content=profile&utm_medium=android_app',
                    ),
                    _teamMemberCard(
                      context,
                      'assets/about_Us_Images/Gopi_sir.jpeg',
                      'Gopikrishnan Kanan',
                      'TECHNICAL MANAGER',
                      'https://www.linkedin.com/in/gopikrishnan-kanan/',
                    ),
                    _teamMemberCard(
                      context,
                      'assets/about_Us_Images/Pitambar_sir.jpeg',
                      'Pitambar Thapa',
                      'PROJECT MANAGER',
                      'https://www.linkedin.com/in/pitambar-thapa-40158516?utm_source=share&utm_campaign=share_via&utm_content=profile&utm_medium=android_app',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Development Team Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                BounceInDown(
                  duration: Duration(milliseconds: 1600),
                  child: Text(
                    'Development Team',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Wrap(
                  spacing: 20.0,
                  runSpacing: 20.0,
                  alignment: WrapAlignment.center,
                  children: [
                    _teamMemberCard(
                      context,
                      'assets/about_Us_Images/Yash.jpg',
                      'Yash Lande',
                      'PROJECT TEAM Leader',
                      'https://www.linkedin.com/in/yash-lande-6a169432a/',
                    ),
                    _teamMemberCard(
                      context,
                      'assets/about_Us_Images/aman.jpg',
                      'Amaan Bharde',
                      'PROJECT TEAM Leader',
                      'https://www.linkedin.com/in/amaan-bharde-2aa504180/',
                    ),
                    _teamMemberCard(
                      context,
                      'assets/about_Us_Images/Siddharth.JPG',
                      'Siddharth Nilekar',
                      'PROJECT TEAM Member',
                      'https://www.linkedin.com/in/siddharth-nilekar/',
                    ),
                    _teamMemberCard(
                      context,
                      'assets/about_Us_Images/Anushka.jpg',
                      'Anushka Jadhav',
                      'PROJECT TEAM Member',
                      'https://www.linkedin.com/in/anushka1407/',
                    ),
                    _teamMemberCard(
                      context,
                      'assets/about_Us_Images/vaibhav.jpeg',
                      'Vaibhav Gaikwad',
                      'PROJECT TEAM Member',
                      'https://www.linkedin.com/in/vaibhav-gaikwad-18dev/',
                    ),
                    _teamMemberCard(
                      context,
                      'assets/about_Us_Images/uddesh.jpeg',
                      'Uddesh Tilak',
                      'PROJECT TEAM Member',
                      'https://www.linkedin.com/in/uddeshtilak/',
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _teamMemberCard(
    BuildContext context,
    String imageUrl,
    String name,
    String role,
    String linkedInUrl,
  ) {
    return BounceInUp(
      duration: Duration(milliseconds: 1800),
      child: GestureDetector(
        onTap: () => _launchUrl(linkedInUrl),
        child: Column(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade200,
                    child: Center(child: Text('Image failed to load')),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            Text(
              role,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  void _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
    }
  }
}