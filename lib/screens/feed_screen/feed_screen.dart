import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:instagram/models/models.dart';
import 'package:instagram/services/services.dart';
import 'package:instagram/utilities/constants.dart';
import 'package:instagram/utilities/repo_const.dart';
import 'package:instagram/utilities/themes.dart';
import 'package:instagram/screens/feed_screen/widgets/stories_widget.dart';
import 'package:instagram/widgets/instaDart_richText.dart';
import 'package:instagram/widgets/post_view.dart';
import 'package:provider/provider.dart';

class FeedScreen extends StatefulWidget {
  static final String id = 'feed_screen';
  final String currentUserId;
  final Function goToDirectMessages;
  final Function goToCameraScreen;

  FeedScreen(
      {this.currentUserId, this.goToDirectMessages, this.goToCameraScreen});
  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Post> _posts = [];
  bool _isLoadingFeed = false;
  bool _isLoadingStories = false;
  List<User> _followingUsersWithStories = [];

  @override
  void initState() {
    super.initState();
    _setupFeed();
  }

  _setupFeed() async {
    _setupStories();

    setState(() => _isLoadingFeed = true);
    List<Post> posts = await DatabaseService.getFeedPosts(
      widget.currentUserId,
    );

    // List<Post> posts = await DatabaseService.getAllFeedPosts();
    setState(() {
      _posts = posts;
      _isLoadingFeed = false;
    });
  }

  void _setupStories() async {
    setState(() => _isLoadingStories = true);

    // Get currentUser followingUsers
    List<User> followingUsers =
        await DatabaseService.getUserFollowingUsers(widget.currentUserId);

    if (!mounted) return;
    User currentUser =
        Provider.of<UserData>(context, listen: false).currentUser;

    /* A method to add Admin stories to each user */
    if (currentUser.id != kAdminUId) {
      bool isFollowingAdmin = false;

      for (User user in followingUsers) {
        if (user.id == kAdminUId) {
          isFollowingAdmin = true;
        }
      }
      // if current user doesn't follow admin
      if (!isFollowingAdmin) {
        // get admin stories
        List<Story> adminStories =
            await StoriesService.getStoriesByUserId(kAdminUId, true);
        if (!mounted) return;
        // if there is admin stories
        if (adminStories != null && adminStories.isNotEmpty) {
          // get admin user
          User adminUser = await DatabaseService.getUserWithId(kAdminUId);
          if (!mounted) return;
          // add admin to story circle list
          followingUsers.insert(0, adminUser);
        }
      }
    }
    /* End of method to add Admin stories to each user */

    // Add current user to the first story circle
    followingUsers.insert(0, currentUser);

    if (mounted) {
      setState(() {
        _isLoadingStories = false;
        _followingUsersWithStories = followingUsers;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.color,
        centerTitle: true,
        title:
            InstaDartRichText(kBillabongFamilyTextStyle.copyWith(fontSize: 40)),
        actions: [
          IconButton(
              icon: FaIcon(FontAwesomeIcons.paperPlane),
              // onPressed: () => Navigator.push(context,
              //     MaterialPageRoute(builder: (_) => DirectMessagesScreen())))
              onPressed: widget.goToDirectMessages),
        ],
      ),
      body: !_isLoadingFeed
          ? RefreshIndicator(
              // If posts finished loading
              onRefresh: () => _setupFeed(),
              child: SingleChildScrollView(
                physics: ScrollPhysics(),
                child: Column(
                  children: [
                    _isLoadingStories
                        ? Container(
                            height: 88,
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : StoriesWidget(_followingUsersWithStories,
                            widget.currentUserId, widget.goToCameraScreen),
                    SizedBox(height: 5),
                    ListView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: _posts.length > 0 ? _posts.length : 1,
                      itemBuilder: (BuildContext context, int index) {
                        if (_posts.length == 0) {
                          //If there is no posts
                          return Container(
                            height: MediaQuery.of(context).size.height,
                            child: Center(
                              child:
                                  Text('No posts found, Start following users'),
                            ),
                          );
                        }

                        Post post = _posts[index];

                        return FutureBuilder(
                          future: DatabaseService.getUserWithId(post.authorId),
                          builder:
                              (BuildContext context, AsyncSnapshot snapshot) {
                            if (!snapshot.hasData) {
                              return SizedBox.shrink();
                            }

                            User author = snapshot.data;

                            return PostView(
                              postStatus: PostStatus.feedPost,
                              currentUserId: widget.currentUserId,
                              author: author,
                              post: post,
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            )
          : Center(
              // If posts is loading
              child: CircularProgressIndicator(),
            ),
    );
  }
}