import 'dart:async';
import 'dart:convert';

import 'package:feedback/feedback.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// A data type holding user feedback consisting of a feedback type, free from
/// feedback text, and a sentiment rating.
class CustomFeedback {
  CustomFeedback({
    this.feedbackType,
    this.feedbackText,
    this.withScreenshot,
  });

  FeedbackType? feedbackType;
  String? feedbackText;
  bool? withScreenshot;

  @override
  String toString() {
    return '''
      feedback_type: $feedbackType
      feedback_text: $feedbackText
    ''';
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': feedbackType,
      'title': switch (feedbackType) {
        null => '',
        FeedbackType.HarmfulContent => 'Harmful or Offensive Content',
        FeedbackType.InappropriateContent => 'Inappropriate Content',
        FeedbackType.InaccurateContent => 'Factually Inaccurate Content',
        FeedbackType.GeneralIssue => 'Other Issues',
      },
      'text': feedbackText,
      'screenshot': withScreenshot ?? false,
    };
  }
}

/// What type of feedback the user wants to provide.
enum FeedbackType {
  HarmfulContent(1),
  InappropriateContent(2),
  InaccurateContent(3),
  GeneralIssue(4);

  final int value;
  const FeedbackType(this.value);

  static FeedbackType fromValue(int v) {
    return switch (v) {
      1 => HarmfulContent,
      2 => InappropriateContent,
      3 => InaccurateContent,
      4 => GeneralIssue,
      _ => GeneralIssue,
    };
  }
}

/// A user-provided sentiment rating.
enum FeedbackRating {
  bad,
  neutral,
  good,
}

/// A form that prompts the user for the type of feedback they want to give,
/// free form text feedback, and a sentiment rating.
/// The submit button is disabled until the user provides the feedback type. All
/// other fields are optional.
class UnnuCustomFeedbackForm extends StatefulWidget {
  const UnnuCustomFeedbackForm({
    super.key,
    required this.onSubmit,
    required this.scrollController,
  });

  final OnSubmit onSubmit;
  final ScrollController? scrollController;

  @override
  State<UnnuCustomFeedbackForm> createState() => _UnnuCustomFeedbackFormState();
}

class _UnnuCustomFeedbackFormState extends State<UnnuCustomFeedbackForm> {
  final CustomFeedback _customFeedback = CustomFeedback();

  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: ScrollController(
        keepScrollOffset: false,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.zero,
          border: BoxBorder.all(width: 0.5),
        ),
        padding: EdgeInsets.zero,
        child: FormBuilder(
          key: _formKey,
          child: SingleChildScrollView(
            controller: widget.scrollController,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.zero,
                border: BoxBorder.all(width: 0.5),
              ),
              constraints: BoxConstraints(
                minWidth: MediaQuery.sizeOf(context).width,
                maxWidth: MediaQuery.sizeOf(context).width,
              ),
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  FormBuilderRadioGroup(
                    decoration: const InputDecoration(
                      hintText: 'Select type of feedback',
                      labelText: 'What kind of feedback do you want to give?',
                      icon: const Icon(
                        Icons.report,
                      ),
                      // helperText:
                      //     'Context window size in tokens, update trigger model reload',
                    ),
                    initialValue: _customFeedback.feedbackType,
                    validator: FormBuilderValidators.required(),
                    options:
                        FeedbackType.values
                            .map(
                              (
                                type,
                              ) => FormBuilderFieldOption<int>(
                                value: type.value,
                                child: switch (type) {
                                  FeedbackType.HarmfulContent => const Text(
                                    'Harmful',
                                  ),
                                  FeedbackType.InappropriateContent =>
                                    const Text(
                                      'Inappropriate',
                                    ),
                                  FeedbackType.InaccurateContent => const Text(
                                    'Inaccurate',
                                  ),
                                  FeedbackType.GeneralIssue => const Text(
                                    'Other',
                                  ),
                                },
                              ),
                            )
                            .toList(),
                    valueTransformer:
                        (value) => FeedbackType.fromValue(
                          (value ?? FeedbackType.GeneralIssue.value) as int,
                        ),
                    onChanged:
                        (value) => setState(
                          () =>
                              _customFeedback
                                  .feedbackType = FeedbackType.fromValue(
                                (value ?? FeedbackType.GeneralIssue.value) as int,
                              ),
                        ),
                    name: 'feedback_type',
                  ),
                  FormBuilderCheckbox(
                    name: 'feedback_screenshot',
                    decoration: const InputDecoration(
                      hintText: 'Automatically send screenshot with feedback',
                      labelText: 'Include screenshot',
                      icon: Icon(
                        Icons.screenshot,
                      ),
                      // helperText:
                      //     'Sampling strategies applied to token sampling and generation',
                    ),
                    title: const Text('Include screenshot?'),
                    initialValue: _customFeedback.withScreenshot,
                    onChanged:
                        (value) => setState(() => _customFeedback.withScreenshot = value),
                  ),
                  if (_customFeedback.feedbackType != null)
                    FormBuilderTextField(
                      name: 'feedback_text',
                      decoration: InputDecoration(
                        hintText: switch(_customFeedback.feedbackType) {
                          null => 'Please provide for feedback',
                          FeedbackType.HarmfulContent => 'Describe what was harmful',
                          FeedbackType.InappropriateContent => 'Describe what was inappropriate',
                          FeedbackType.InaccurateContent => 'Describe what was inaccurate',
                          FeedbackType.GeneralIssue =>  'Please provide for feedback',
                        },

                        labelText: 'Feedback',
                        icon: const Icon(
                          Icons.edit,
                        ),
                        // helperText:
                        //     'Context window size in tokens, update trigger model reload',
                      ),
                      minLines: 1,
                      maxLines: 10,
                      onChanged:
                          (newFeedback) =>
                              _customFeedback.feedbackText = newFeedback,
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed:
                    _formKey.currentState?.saveAndValidate() ?? false
                        ? () => widget.onSubmit(switch(_customFeedback.feedbackType) {
                      null => 'General feedback',
                      FeedbackType.HarmfulContent => 'CRITICAL: Harmful content reported',
                      FeedbackType.InappropriateContent => 'SEVERE: Inappropriate content reported',
                      FeedbackType.InaccurateContent => 'WARNING: Inaccurate content reported',
                      FeedbackType.GeneralIssue =>  'General feedback',
                    },
                      extras: _customFeedback.toMap(),
                    )
                        : null,
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// This is an extension to make it easier to call
/// [showAndUploadToGitLab].
extension BetterFeedbackX on FeedbackController {
  /// Example usage:
  /// ```dart
  /// import 'package:feedback_gitlab/feedback_gitlab.dart';
  ///
  /// RaisedButton(
  ///   child: Text('Click me'),
  ///   onPressed: (){
  ///     BetterFeedback.of(context).showAndUploadToGitLab
  ///       projectId: 'gitlab-project-id',
  ///       apiToken: 'gitlab-api-token',
  ///       gitlabUrl: 'gitlab.org', // optional, defaults to 'gitlab.com'
  ///     );
  ///   }
  /// )
  /// ```
  /// The API token needs access to:
  ///   - read_api
  ///   - write_repository
  /// See https://docs.gitlab.com/ee/user/project/settings/project_access_tokens.html#limiting-scopes-of-a-project-access-token
  void showAndUploadToGitLab({
    required String projectId,
    required String apiToken,
    String? gitlabUrl,
    http.Client? client,
    String? contents,
  }) {
    show(
     uploadToGitLab(
        projectId: projectId,
        apiToken: apiToken,
        gitlabUrl: gitlabUrl,
        client: client,
      ),
    );
  }
}

/// See [BetterFeedbackX.showAndUploadToGitLab].
/// This is just [visibleForTesting].
@visibleForTesting
OnFeedbackCallback uploadToGitLab({
  required String projectId,
  required String apiToken,
  String? gitlabUrl,
  http.Client? client,
  String? contents,
}) {
  final httpClient = client ?? http.Client();
  final baseUrl = gitlabUrl ?? 'gitlab.com';

  return (UserFeedback feedback) async {
    final extras = feedback.extra ?? <String, dynamic>{};
    final withScreenshot = (extras['screenshot'] ?? false) as bool;
    String? imageMarkdown;
    if (withScreenshot) {
      final uri = Uri.https(
        baseUrl,
        '/api/v4/projects/$projectId/uploads',
      );
      final uploadRequest =
          http.MultipartRequest('POST', uri)
            ..headers.putIfAbsent('PRIVATE-TOKEN', () => apiToken)
            ..fields['id'] = projectId
            ..files.add(
              http.MultipartFile.fromBytes(
                'file',
                feedback.screenshot,
                filename: 'feedback.png',
                contentType: MediaType('image', 'png'),
              ),
            );
      final uploadResponse = await httpClient.send(uploadRequest);
      final dynamic uploadResponseMap = jsonDecode(
        await uploadResponse.stream.bytesToString(),
      );
      imageMarkdown = uploadResponseMap["markdown"] as String?;
    }
    final additionalContents =
        contents != null ? contents: '';
    final description =
        '${(extras['title'] ?? '') as String}\n'
        '${(extras['text'] ?? '') as String}\n'
        '${imageMarkdown ?? ''}\n'
        '------------------------------\n'
        '$additionalContents\n';

    // Create issue
    final response = await httpClient.post(
      Uri.https(
        baseUrl,
        '/api/v4/projects/$projectId/issues',
        <String, dynamic>{
          'title': feedback.text,
          'description': description,
        },
      ),
      headers: {'PRIVATE-TOKEN': apiToken},
    );
    // if(context.mounted){
    //   BetterFeedback.of(context).hide();
    // }
  };
}
