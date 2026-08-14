import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'dropbox_service.dart';

class DropboxPage extends StatefulWidget {
  const DropboxPage({
    super.key,
  });

  @override
  State<DropboxPage> createState() =>
      _DropboxPageState();
}

class _DropboxPageState
    extends State<DropboxPage> {

  final DropboxService dropbox =
  DropboxService();

  bool connected = false;
  bool loading = false;

  String accountName = '';

  List<dynamic> files = [];

  String currentPath = '';

  @override
  void initState() {
    super.initState();

    handleDropboxCallback();
  }

  // ============================================================
  // HANDLE OAUTH CALLBACK
  // ============================================================

  Future<void> handleDropboxCallback() async {
    try {
      final success =
      await dropbox.handleCallback();

      if (!success) {
        return;
      }

      if (!mounted) return;

      await loadAccount();
      await loadFiles();
    } catch (e) {
      debugPrint(
        'Dropbox callback error: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Dropbox connection failed: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // CONNECT
  // ============================================================

  Future<void> connect() async {
    try {
      await dropbox.connectDropbox();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Could not open Dropbox: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // LOAD ACCOUNT
  // ============================================================

  Future<void> loadAccount() async {
    try {
      final account =
      await dropbox.getAccountInfo();

      if (account == null) {
        return;
      }

      if (!mounted) return;

      setState(() {
        connected = true;

        accountName =
            account['name']
            ?['display_name'] ??
                '';
      });
    } catch (e) {
      debugPrint(
        'Account error: $e',
      );
    }
  }

  // ============================================================
  // LOAD FILES
  // ============================================================

  Future<void> loadFiles({
    String path = '',
  }) async {
    setState(() {
      loading = true;
    });

    try {
      final result =
      await dropbox.listFiles(
        path: path,
      );

      if (!mounted) return;

      setState(() {
        files = result;
        currentPath = path;
      });
    } catch (e) {
      debugPrint(
        'Files error: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Could not load Dropbox files: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // ============================================================
  // OPEN FOLDER
  // ============================================================

  Future<void> openFolder(
      String path,
      ) async {
    await loadFiles(
      path: path,
    );
  }

  // ============================================================
  // GO BACK
  // ============================================================

  Future<void> goBack() async {
    if (currentPath.isEmpty) {
      return;
    }

    final uri =
    currentPath.split('/');

    uri.removeLast();

    final parent =
    uri.join('/');

    await loadFiles(
      path: parent,
    );
  }

  // ============================================================
  // VIDEO PREVIEW
  // ============================================================

  Future<void> previewVideo(
      String path,
      String name,
      ) async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return VideoPreviewDialog(
          dropbox: dropbox,
          path: path,
          name: name,
        );
      },
    );
  }

  // ============================================================
  // FILE ICON
  // ============================================================

  IconData getFileIcon(
      dynamic file,
      ) {
    final tag =
    file['.tag'];

    if (tag == 'folder') {
      return Icons.folder;
    }

    final name =
    file['name']
        ?.toString();

    if (dropbox.isVideo(name)) {
      return Icons.video_file;
    }

    if (dropbox.isImage(name)) {
      return Icons.image;
    }

    return Icons.insert_drive_file;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dropbox',
        ),
        actions: [
          if (connected)
            IconButton(
              tooltip: 'Refresh',
              onPressed: () {
                loadFiles(
                  path: currentPath,
                );
              },
              icon: const Icon(
                Icons.refresh,
              ),
            ),

          if (connected)
            IconButton(
              tooltip: 'Disconnect',
              onPressed: () async {
                await dropbox.logout();

                if (!mounted) return;

                setState(() {
                  connected = false;
                  accountName = '';
                  files = [];
                  currentPath = '';
                });
              },
              icon: const Icon(
                Icons.logout,
              ),
            ),
        ],
      ),

      body: Padding(
        padding:
        const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            // ==================================================
            // CONNECT BUTTON
            // ==================================================

            if (!connected)
              ElevatedButton.icon(
                onPressed: connect,
                icon: const Icon(
                  Icons.cloud,
                ),
                label: const Text(
                  'Connect Dropbox',
                ),
              ),

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // ACCOUNT
            // ==================================================

            if (connected)
              Container(
                padding:
                const EdgeInsets.all(16),

                decoration:
                BoxDecoration(
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                  color: Colors.green
                      .withOpacity(.1),
                ),

                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child: Text(
                        'Connected as: '
                            '$accountName',
                        style:
                        const TextStyle(
                          fontSize: 16,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // FOLDER NAVIGATION
            // ==================================================

            if (connected)
              Row(
                children: [

                  if (currentPath.isNotEmpty)
                    IconButton(
                      onPressed: goBack,
                      icon: const Icon(
                        Icons.arrow_back,
                      ),
                    ),

                  Expanded(
                    child: Text(
                      currentPath.isEmpty
                          ? 'Dropbox'
                          : currentPath,
                      style:
                      const TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(
              height: 10,
            ),

            // ==================================================
            // FILES
            // ==================================================

            if (!connected)
              const Expanded(
                child: Center(
                  child: Text(
                    'Connect your Dropbox to view files.',
                  ),
                ),
              )
            else if (loading)
              const Expanded(
                child: Center(
                  child:
                  CircularProgressIndicator(),
                ),
              )
            else if (files.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No files found.',
                    ),
                  ),
                )
              else
                Expanded(
                  child:
                  ListView.builder(
                    itemCount:
                    files.length,

                    itemBuilder:
                        (context, index) {
                      final file =
                      files[index];

                      final isFolder =
                          file['.tag'] ==
                              'folder';

                      final name =
                          file['name']
                              ?.toString() ??
                              '';

                      final path =
                          file['path_display']
                              ?.toString() ??
                              '';

                      return Card(
                        margin:
                        const EdgeInsets
                            .only(
                          bottom: 8,
                        ),

                        child:
                        ListTile(
                          leading:
                          Icon(
                            getFileIcon(
                              file,
                            ),
                          ),

                          title:
                          Text(
                            name,
                          ),

                          subtitle:
                          Text(
                            path,
                          ),

                          trailing:
                          isFolder
                              ? const Icon(
                            Icons
                                .chevron_right,
                          )
                              : dropbox
                              .isVideo(
                            name,
                          )
                              ? IconButton(
                            icon:
                            const Icon(
                              Icons
                                  .play_circle,
                            ),
                            onPressed:
                                () {
                              previewVideo(
                                path,
                                name,
                              );
                            },
                          )
                              : null,

                          onTap: isFolder
                              ? () {
                            openFolder(
                              path,
                            );
                          }
                              : dropbox
                              .isVideo(
                            name,
                          )
                              ? () {
                            previewVideo(
                              path,
                              name,
                            );
                          }
                              : null,
                        ),
                      );
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// VIDEO PREVIEW DIALOG
// ================================================================

class VideoPreviewDialog
    extends StatefulWidget {

  final DropboxService dropbox;
  final String path;
  final String name;

  const VideoPreviewDialog({
    super.key,
    required this.dropbox,
    required this.path,
    required this.name,
  });

  @override
  State<VideoPreviewDialog>
  createState() =>
      _VideoPreviewDialogState();
}

class _VideoPreviewDialogState
    extends State<VideoPreviewDialog> {

  VideoPlayerController?
  controller;

  bool loading = true;

  String? error;

  @override
  void initState() {
    super.initState();

    loadVideo();
  }

  // ============================================================
  // LOAD VIDEO
  // ============================================================

  Future<void> loadVideo() async {
    try {
      final url =
      await widget.dropbox
          .getTemporaryLink(
        widget.path,
      );

      if (url == null) {
        throw Exception(
          'Could not get Dropbox video link.',
        );
      }

      controller =
          VideoPlayerController
              .networkUrl(
            Uri.parse(url),
          );

      await controller!
          .initialize();

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Dialog(
      child: Container(
        constraints:
        const BoxConstraints(
          maxWidth: 1000,
          maxHeight: 700,
        ),

        padding:
        const EdgeInsets.all(20),

        child: Column(
          mainAxisSize:
          MainAxisSize.min,

          children: [

            Row(
              children: [

                Expanded(
                  child: Text(
                    widget.name,
                    style:
                    const TextStyle(
                      fontSize: 18,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),

                IconButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );
                  },
                  icon: const Icon(
                    Icons.close,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 20,
            ),

            if (loading)
              const Padding(
                padding:
                EdgeInsets.all(50),
                child:
                CircularProgressIndicator(),
              )

            else if (error != null)
              Padding(
                padding:
                const EdgeInsets.all(30),
                child: Text(
                  error!,
                ),
              )

            else if (controller != null &&
                  controller!
                      .value
                      .isInitialized)
                Column(
                  children: [

                    AspectRatio(
                      aspectRatio:
                      controller!
                          .value
                          .aspectRatio,

                      child:
                      VideoPlayer(
                        controller!,
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    IconButton(
                      iconSize: 50,

                      onPressed: () {
                        setState(() {
                          if (controller!
                              .value
                              .isPlaying) {
                            controller!
                                .pause();
                          } else {
                            controller!
                                .play();
                          }
                        });
                      },

                      icon: Icon(
                        controller!
                            .value
                            .isPlaying
                            ? Icons
                            .pause_circle
                            : Icons
                            .play_circle,
                      ),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}