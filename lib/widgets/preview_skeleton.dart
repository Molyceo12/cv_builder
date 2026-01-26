import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class PreviewSkeleton extends StatelessWidget {
  const PreviewSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Left Sidebar (Modern Green Theme)
          Container(
            width: 190,
            color: const Color(0xFF064E3B), // Exact green from template
            child: Shimmer.fromColors(
              baseColor: Colors.white.withOpacity(0.1),
              highlightColor: Colors.white.withOpacity(0.2),
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and Title placeholder
                    Container(height: 24, width: 140, decoration: _boxDecoration(Colors.white)),
                    const SizedBox(height: 8),
                    Container(height: 14, width: 100, decoration: _boxDecoration(Colors.white)),
                    
                    const SizedBox(height: 35),
                    
                    // "Personal details" header
                    Container(height: 16, width: 90, decoration: _boxDecoration(Colors.white)),
                    const SizedBox(height: 15),
                    
                    // Contact items
                    ...List.generate(5, (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(height: 12, width: 12, decoration: _boxDecoration(Colors.white, shape: BoxShape.circle)),
                          const SizedBox(width: 10),
                          Container(height: 10, width: index == 0 ? 120 : (80 + (index * 10).toDouble()), decoration: _boxDecoration(Colors.white)),
                        ],
                      ),
                    )),
                    
                    const SizedBox(height: 35),
                    // "Skills" header
                    Container(height: 16, width: 60, decoration: _boxDecoration(Colors.white)),
                    const SizedBox(height: 15),
                    
                    // Skill sliders
                    ...List.generate(4, (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(height: 10, width: 70 + (index * 15).toDouble(), decoration: _boxDecoration(Colors.white)),
                          const SizedBox(height: 6),
                          Container(height: 6, width: 150, decoration: _boxDecoration(Colors.white, radius: 3)),
                        ],
                      ),
                    )),

                    const SizedBox(height: 30),
                    // "Languages" header
                    Container(height: 16, width: 70, decoration: _boxDecoration(Colors.white)),
                    const SizedBox(height: 15),
                    Container(height: 6, width: 150, decoration: _boxDecoration(Colors.white, radius: 3)),
                  ],
                ),
              ),
            ),
          ),
          
          // Right Content Area
          Expanded(
            child: Shimmer.fromColors(
              baseColor: Colors.grey[200]!,
              highlightColor: Colors.grey[50]!,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(left: 30, right: 30, top: 25, bottom: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Section
                    Container(height: 18, width: 100, decoration: _boxDecoration(Colors.white)),
                    const SizedBox(height: 5),
                    Container(height: 1.5, width: double.infinity, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    ...List.generate(3, (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        height: 10, 
                        width: index == 2 ? 200 : double.infinity, 
                        decoration: _boxDecoration(Colors.white)
                      ),
                    )),
                    
                    const SizedBox(height: 25),
                    
                    // Experience Header
                    Container(height: 22, width: 140, decoration: _boxDecoration(Colors.white)),
                    const SizedBox(height: 8),
                    Container(height: 1.5, width: double.infinity, color: Colors.grey[300]),
                    const SizedBox(height: 15),
                    
                    // Experience Items
                    ...List.generate(2, (index) => _buildSectionItem()),
                    
                    const SizedBox(height: 20),
                    
                    // Education Header
                    Container(height: 22, width: 140, decoration: _boxDecoration(Colors.white)),
                    const SizedBox(height: 8),
                    Container(height: 1.5, width: double.infinity, color: Colors.grey[300]),
                    const SizedBox(height: 15),
                    
                    // Education Item
                    _buildSectionItem(lines: 1),
                    
                    const SizedBox(height: 20),
                    
                    // Projects Header
                    Container(height: 22, width: 140, decoration: _boxDecoration(Colors.white)),
                    const SizedBox(height: 8),
                    Container(height: 1.5, width: double.infinity, color: Colors.grey[300]),
                    const SizedBox(height: 15),
                    
                    // Project Item
                    _buildSectionItem(lines: 2),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionItem({int lines = 2}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(height: 14, width: 180, decoration: _boxDecoration(Colors.white)),
              Container(height: 11, width: 90, decoration: _boxDecoration(Colors.white)),
            ],
          ),
          const SizedBox(height: 6),
          Container(height: 11, width: 130, decoration: _boxDecoration(Colors.white)),
          const SizedBox(height: 12),
          ...List.generate(lines, (idx) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 4, right: 8),
                  height: 4, width: 4, 
                  decoration: _boxDecoration(Colors.grey[400]!, shape: BoxShape.circle)
                ),
                Expanded(
                  child: Container(
                    height: 10, 
                    width: double.infinity, 
                    decoration: _boxDecoration(Colors.white)
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  BoxDecoration _boxDecoration(Color color, {double radius = 4, BoxShape shape = BoxShape.rectangle}) {
    return BoxDecoration(
      color: color,
      shape: shape,
      borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(radius),
    );
  }
}
