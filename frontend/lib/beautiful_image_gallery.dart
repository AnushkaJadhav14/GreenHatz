import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:animate_do/animate_do.dart';
import 'image_full_screen_viewer.dart';

class BeautifulImageGallery extends StatelessWidget {
  final String corporateId;

  BeautifulImageGallery({Key? key, required this.corporateId}) : super(key: key);

  final List<Map<String, String>> imageList = [
    {
      'imageUrl': 'assets/gallary_images/Green_Hatz_project_Team.jpg',
      'title': 'The Green Hatz Project team',
      'description': 'The Green Hatz Project team stands together in an office meeting room, engaged in an active discussion about idea evolution, with the Project Manager leading and team members contributing enthusiastically.',
    },
    {
      'imageUrl': 'assets/gallary_images/Distinguished NBFC Award 2024(DNA).jpg',
      'title': 'Distinguished NBFC Award 2024(DNA)',
      'description': 'The photo captures the Distinguished NBFC Award 2024 (DNA) ceremony at The NBFC Tomorrow Conclave & DNA Awards 2024, held in Mumbai on August 21, where the achievements of NBFCs were celebrated for their impact on the financial sector.',
    },
    {
      'imageUrl': 'assets/gallary_images/Green_Hatz_project_Team2.jpg',
      'title': 'The Green Hatz Project team',
      'description': 'The Green Hatz Project team stands proudly together, displaying a strong sense of unity and collaboration.',
    },
    {
      'imageUrl': 'assets/gallary_images/Idea generation camp.jpg',
      'title': 'The Idea Generation Camp',
      'description': 'The Idea Generation Camp shows employees in a lively office hall brainstorming and collaborating on innovative ideas to evolve the workplace.',
    },
    {
      'imageUrl': 'assets/gallary_images/CEO Sir.jpg',
      'title': 'The CEO Sir',
      'description': 'The CEO is in the meeting room, leading a discussion with employees and committee members about idea generation for the companys growth.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: MasonryGridView.count(
                  crossAxisCount: _getCrossAxisCount(context),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  itemCount: imageList.length,
                  itemBuilder: (context, index) {
                    return _buildImageCard(context, index);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          FadeInDown(
            duration: Duration(milliseconds: 800),
            child: Text(
              'Project Gallary',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ),
          SizedBox(height: 8),
          FadeInUp(
            duration: Duration(milliseconds: 1000),
            child: Text(
              'Explore Beautiful Moments',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  int _getCrossAxisCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 1200)
      return 4;
    else if (width > 800)
      return 3;
    else if (width > 600)
      return 2;
    else
      return 1;
  }

  Widget _buildImageCard(BuildContext context, int index) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageFullScreenViewer(
              imageList: imageList,
              initialIndex: index,
            ),
          ),
        );
      },
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                imageList[index]['imageUrl']!,
                fit: BoxFit.cover,
                height: 200,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey.shade200,
                  child: Center(child: Text('Image failed to load')),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                imageList[index]['title']!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
