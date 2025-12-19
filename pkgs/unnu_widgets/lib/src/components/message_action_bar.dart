import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hold_to_confirm_button/hold_to_confirm_button.dart';

enum ButtonNature { Button, Holdable, Action }

enum ButtonVariant { Normal, Outlined, Filled }

enum ButtonType { IconOnly, TextOnly, Chip }

typedef ButtonWidget = ({Widget icon, Widget text});

@immutable
final class MessageActionButton {
  final IconData icon;
  final IconData secondaryIcon;
  final String title;
  final VoidCallback onPressed;
  final bool destructive;
  final bool enabled;
  final ButtonVariant variant;
  final ButtonType type;
  final ButtonNature nature;

  const MessageActionButton({
    required this.icon,
    required this.title,
    required this.onPressed,
    IconData? secondaryIcon,
    this.destructive = false,
    this.enabled = true,
    this.variant = ButtonVariant.Normal,
    this.type = ButtonType.Chip,
    this.nature = ButtonNature.Button,
  }) : secondaryIcon = secondaryIcon ?? icon;

  MessageActionButton copyWith({
    IconData? icon,
    IconData? secondaryIcon,
    String? title,
    VoidCallback? onPressed,
    bool? destructive,
    bool? enabled,
    ButtonVariant? variant,
    ButtonType? type,
    ButtonNature? nature,
  }) {
    return MessageActionButton(
      icon: icon ?? this.icon,
      secondaryIcon: secondaryIcon ?? this.secondaryIcon ?? this.icon,
      title: title ?? this.title,
      onPressed: onPressed ?? this.onPressed,
      destructive: destructive ?? this.destructive,
      enabled: enabled ?? this.enabled,
      variant: variant ?? this.variant,
      type: type ?? this.type,
      nature: nature ?? this.nature,
    );
  }

  @override
  String toString() {
    return 'MessageActionButton(icon: $icon, secondaryIcon: $secondaryIcon, title: $title, onPressed: $onPressed, destructive: $destructive, enabled: $enabled, variant: $variant, type: $type, nature: $nature)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MessageActionButton &&
        other.icon == icon &&
        other.secondaryIcon == secondaryIcon &&
        other.title == title &&
        other.onPressed == onPressed &&
        other.destructive == destructive &&
        other.enabled == enabled &&
        other.variant == variant &&
        other.type == type &&
        other.nature == nature;
  }

  @override
  int get hashCode {
    return icon.hashCode ^
        secondaryIcon.hashCode ^
        title.hashCode ^
        onPressed.hashCode ^
        destructive.hashCode ^
        enabled.hashCode ^
        variant.hashCode ^
        type.hashCode ^
        nature.hashCode;
  }
}

class MessageActionBar extends StatelessWidget {
  final List<MessageActionButton> buttons;
  const MessageActionBar({super.key, required this.buttons});

  @override
  Widget build(BuildContext context) {
    final buttonTheme = ButtonTheme.of(context);
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          children: [
            for (var i = 0; i < buttons.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _button(buttons[i], buttonTheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _button(MessageActionButton button, ButtonThemeData theme) {
    final fgColor = switch (button.variant) {
      ButtonVariant.Normal =>
        button.destructive ? Colors.red : theme.colorScheme?.primary,
      ButtonVariant.Outlined =>
        button.destructive ? Colors.red : theme.colorScheme?.primary,
      ButtonVariant.Filled =>
        button.destructive ? Colors.red : theme.colorScheme?.onPrimary,
    };

    final bgColor = switch (button.variant) {
      ButtonVariant.Normal => theme.colorScheme?.surface,
      ButtonVariant.Outlined => Colors.transparent,
      ButtonVariant.Filled => theme.colorScheme?.primary,
    };

    final childWidget =
        (
              icon: Icon(
                size: 18,
                button.icon,
                color: fgColor,
              ),
              text: Text(
                button.title,
                style: TextStyle(
                  color: fgColor,
                ),
              ),
            )
            as ButtonWidget;

    return switch (button.nature) {
      ButtonNature.Button => switch (button.type) {
        ButtonType.IconOnly => switch (button.variant) {
          ButtonVariant.Normal => IconButton(
            tooltip: button.title,
            icon: childWidget.icon,
            style: IconButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(10),
            ),
            onPressed: button.onPressed,
          ),
          ButtonVariant.Outlined => IconButton.outlined(
            tooltip: button.title,
            icon: childWidget.icon,
            style: IconButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(10),
            ),
            onPressed: button.onPressed,
          ),
          ButtonVariant.Filled => IconButton.filled(
            tooltip: button.title,
            icon: childWidget.icon,
            style: IconButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(10),
            ),
            onPressed: button.onPressed,
          ),
        },
        ButtonType.TextOnly => switch (button.variant) {
          ButtonVariant.Normal => TextButton(
            onPressed: button.onPressed,
            style: TextButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
            child: childWidget.text,
          ),
          ButtonVariant.Outlined => OutlinedButton(
            onPressed: button.onPressed,
            style: TextButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
            child: childWidget.text,
          ),
          ButtonVariant.Filled => FilledButton(
            onPressed: button.onPressed,
            style: TextButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
            child: childWidget.text,
          ),
        },
        ButtonType.Chip => switch (button.variant) {
          ButtonVariant.Normal => TextButton.icon(
            onPressed: button.onPressed,
            label: childWidget.text,
            style: TextButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
            icon: childWidget.icon,
          ),
          ButtonVariant.Outlined => OutlinedButton.icon(
            onPressed: button.onPressed,
            label: childWidget.text,
            style: TextButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
            icon: childWidget.icon,
          ),
          ButtonVariant.Filled => FilledButton.icon(
            onPressed: button.onPressed,
            label: childWidget.text,
            style: TextButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: fgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
            icon: childWidget.icon,
          ),
        },
      },
      ButtonNature.Holdable => switch (button.type) {
        ButtonType.IconOnly => switch (button.variant) {
          ButtonVariant.Normal => Tooltip(
            message: button.title,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: Border.all(width: 2),
              ),
              child: HoldToConfirmButton(
                onProgressCompleted: button.onPressed,
                duration: const Duration(milliseconds: 2100),
                hapticFeedback: false,
                backgroundColor: bgColor ?? Colors.transparent,
                contentPadding: const EdgeInsets.all(10),
                borderRadius: BorderRadius.circular(20),
                child: childWidget.icon,
              ),
            ),
          ),
          ButtonVariant.Outlined => Tooltip(
            message: button.title,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: Border.all(width: 2),
              ),
              child: HoldToConfirmButton(
                onProgressCompleted: button.onPressed,
                duration: const Duration(milliseconds: 2100),
                hapticFeedback: false,
                backgroundColor: bgColor ?? Colors.transparent,
                contentPadding: const EdgeInsets.all(10),
                borderRadius: BorderRadius.circular(20),
                child: childWidget.icon,
              ),
            ),
          ),
          ButtonVariant.Filled => Tooltip(
            message: button.title,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: Border.all(width: 2),
              ),
              child: HoldToConfirmButton(
                onProgressCompleted: button.onPressed,
                duration: const Duration(milliseconds: 2100),
                hapticFeedback: false,
                backgroundColor: bgColor ?? Colors.transparent,
                contentPadding: const EdgeInsets.all(10),
                borderRadius: BorderRadius.circular(20),
                child: childWidget.icon,
              ),
            ),
          ),
        },
        ButtonType.TextOnly => switch (button.variant) {
          ButtonVariant.Normal => Container(
            decoration: BoxDecoration(
              border: Border.all(width: 2),
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            alignment: Alignment.center,
            child: HoldToConfirmButton(
              onProgressCompleted: button.onPressed,
              duration: const Duration(milliseconds: 2100),
              hapticFeedback: false,
              backgroundColor: bgColor ?? Colors.transparent,
              contentPadding: const EdgeInsets.all(2),
              borderRadius: BorderRadius.circular(20),
              child: childWidget.text,
            ),
          ),
          ButtonVariant.Outlined => Container(
            decoration: BoxDecoration(
              border: Border.all(width: 2),
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            alignment: Alignment.center,
            child: HoldToConfirmButton(
              onProgressCompleted: button.onPressed,
              duration: const Duration(milliseconds: 2100),
              hapticFeedback: false,
              backgroundColor: bgColor ?? Colors.transparent,
              contentPadding: const EdgeInsets.all(2),
              borderRadius: BorderRadius.circular(20),
              child: childWidget.text,
            ),
          ),
          ButtonVariant.Filled => Container(
            decoration: BoxDecoration(
              border: Border.all(width: 2),
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            alignment: Alignment.center,
            child: HoldToConfirmButton(
              onProgressCompleted: button.onPressed,
              duration: const Duration(milliseconds: 2100),
              hapticFeedback: false,
              backgroundColor: bgColor ?? Colors.transparent,
              contentPadding: const EdgeInsets.all(2),
              borderRadius: BorderRadius.circular(20),
              child: childWidget.text,
            ),
          ),
        },
        ButtonType.Chip => switch (button.variant) {
          ButtonVariant.Normal => Container(
            decoration: BoxDecoration(
              border: Border.all(width: 2),
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            alignment: Alignment.center,
            child: HoldToConfirmButton(
              onProgressCompleted: button.onPressed,
              duration: const Duration(milliseconds: 2100),
              hapticFeedback: false,
              backgroundColor: bgColor ?? Colors.transparent,
              contentPadding: const EdgeInsets.all(2),
              borderRadius: BorderRadius.circular(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  childWidget.icon,
                  childWidget.text,
                ],
              ),
            ),
          ),
          ButtonVariant.Outlined => Container(
            decoration: BoxDecoration(
              border: Border.all(width: 2),
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            alignment: Alignment.center,
            child: HoldToConfirmButton(
              onProgressCompleted: button.onPressed,
              duration: const Duration(milliseconds: 2100),
              hapticFeedback: false,
              backgroundColor: bgColor ?? Colors.transparent,
              contentPadding: const EdgeInsets.all(2),
              borderRadius: BorderRadius.circular(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  childWidget.icon,
                  childWidget.text,
                ],
              ),
            ),
          ),
          ButtonVariant.Filled => Container(
            decoration: BoxDecoration(
              border: Border.all(width: 2),
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            alignment: Alignment.center,
            child: HoldToConfirmButton(
              onProgressCompleted: button.onPressed,
              duration: const Duration(milliseconds: 2100),
              hapticFeedback: false,
              backgroundColor: bgColor ?? Colors.transparent,
              contentPadding: const EdgeInsets.all(2),
              borderRadius: BorderRadius.circular(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  childWidget.icon,
                  childWidget.text,
                ],
              ),
            ),
          ),
        },
      },
      ButtonNature.Action => switch (button.type) {
        ButtonType.IconOnly => ActionChip(
          tooltip: button.title,
          label: Icon(button.enabled ? button.icon : button.secondaryIcon),
          backgroundColor:
              button.enabled
                  ? theme.colorScheme?.onSurface
                  : bgColor ?? Colors.transparent,
          onPressed: button.onPressed,
        ),
        ButtonType.TextOnly => ActionChip(
          label: childWidget.text,
          backgroundColor:
              button.enabled
                  ? theme.colorScheme?.onSurface
                  : bgColor ?? Colors.transparent,
          onPressed: button.onPressed,
        ),
        ButtonType.Chip => ActionChip(
          avatar: Icon(button.enabled ? button.icon : button.secondaryIcon),
          label: childWidget.text,
          backgroundColor:
              button.enabled
                  ? theme.colorScheme?.onSurface
                  : bgColor ?? Colors.transparent,
          onPressed: button.onPressed,
        ),
      },
    };
  }
}
