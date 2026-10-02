import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:writer_plus/constants/constants.dart';
import 'package:writer_plus/helpers/helpers.dart';
import 'package:writer_plus/reusables/back_button.dart';
import 'package:writer_plus/reusables/writer_plus_logo_text.dart';
import 'package:writer_plus/services/file_service.dart';

class AppInfoPage extends StatefulWidget {
  const AppInfoPage({super.key});

  @override
  State<AppInfoPage> createState() => _AppInfoPageState();
}

class _AppInfoPageState extends State<AppInfoPage> {
  late Future<StorageSummary> _storageSummaryFuture;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _appVersion = '1.0.0 (Build 1)';
    getAppVersion();
    _storageSummaryFuture = FileService().getStorageSummary();
  }

  void getAppVersion() async {
    try {
      final ver = await Helper.getAppVersion();
      if (mounted) {
        setState(() {
          _appVersion = ver;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: const WriterBackButton(),
        titleSpacing: 0.0,
        title: Text(
          'App Info',
          style: Constants.headingTS.copyWith(fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Branding Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  const WriterPlusLogoText(disableOnPress: true),
                  Text(
                    'Made by Adesh(Poz)',
                    style: Constants.bodyTS.copyWith(color: Colors.white54),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Constants.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      'Version $_appVersion',
                      style: TextStyle(
                        color: Constants.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'A sleek, distraction-free markdown and rich text editor designed for fast note-taking, writing, and local document management.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Storage Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionHeader(
                    icon: FontAwesomeIcons.hardDrive,
                    title: 'Storage Statistics',
                  ),
                  const Divider(height: 24, color: Colors.white12),
                  FutureBuilder<StorageSummary>(
                    future: _storageSummaryFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(
                              color: Constants.primaryColor,
                            ),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Text(
                          'Error calculating storage: ${snapshot.error}',
                          style: const TextStyle(color: Colors.redAccent),
                        );
                      }

                      final summary = snapshot.data!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _statTile(
                            icon: FontAwesomeIcons.solidFileLines,
                            label: 'Total Files Saved',
                            value: '${summary.totalFiles} files',
                          ),
                          const SizedBox(height: 12),
                          _statTile(
                            icon: FontAwesomeIcons.solidFolder,
                            label: 'Total Folders',
                            value: '${summary.totalFolders} folders',
                          ),
                          const SizedBox(height: 12),
                          _statTile(
                            icon: FontAwesomeIcons.database,
                            label: 'Total Disk Space Used',
                            value: summary.formattedTotalSize,
                          ),
                          const SizedBox(height: 12),
                          _statTile(
                            icon: FontAwesomeIcons.folderTree,
                            label: 'Storage Path',
                            value: summary.rootPath,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Key Features Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionHeader(
                    icon: FontAwesomeIcons.wandMagicSparkles,
                    title: 'Features & Capabilities',
                  ),
                  Divider(height: 24, color: Colors.white12),
                  // SizedBox(height: 12),
                  _FeatureBullet(
                    'Saved in public root storage on Android (persists across uninstalls)',
                  ),
                  _FeatureBullet('In-app local storage file directory system'),
                  _FeatureBullet(
                    'Supports Plain Text (.txt), Markdown (.md), and Rich Text (.rtf)',
                  ),
                  _FeatureBullet(
                    'Real-time word, character count & reading speed metrics',
                  ),
                  _FeatureBullet('Organize documents into nested subfolders'),
                  _FeatureBullet('External out-of-app sharing functionality'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSectionHeader({required FaIconData icon, required String title}) {
    return Row(
      children: [
        FaIcon(icon, color: Constants.primaryColor, size: 18),
        SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _statTile({
    required FaIconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        FaIcon(icon, color: Constants.primaryColor, size: 16),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  const _FeatureBullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(color: Constants.primaryColor, fontSize: 14),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
