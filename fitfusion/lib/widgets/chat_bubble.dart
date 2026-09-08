import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_message_model.dart';
import '../theme/app_theme.dart';
import 'workout_plan_card.dart';
import 'nutrition_tip_card.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessageModel message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = message.isUser;
    final timeStr = DateFormat('h:mm a').format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // Coach Avatar Badge
            Container(
              width: 34,
              height: 34,
              margin: const EdgeInsets.only(right: 8, top: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],

          // Bubble Body
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: !isUser
                        ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                        : null,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: Border.all(
                      color: isUser
                          ? Colors.transparent
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _formatContent(message.content, isUser, isDark),
                    ],
                  ),
                ),

                // Embedded Workout Plan Card
                if (message.workoutPlan != null)
                  WorkoutPlanCard(plan: message.workoutPlan!),

                // Embedded Nutrition Plan Card
                if (message.nutritionPlan != null)
                  NutritionTipCard(plan: message.nutritionPlan!),

                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _formatContent(String text, bool isUser, bool isDark) {
    if (isUser) {
      return Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      );
    }

    // Markdown-like bold and bullet point renderer for clean rendering
    final lines = text.split('\n');
    List<Widget> lineWidgets = [];

    for (var line in lines) {
      if (line.trim().isEmpty) {
        lineWidgets.add(const SizedBox(height: 6));
        continue;
      }

      if (line.startsWith('### ')) {
        lineWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6, top: 4),
            child: Text(
              line.replaceFirst('### ', ''),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
          ),
        );
      } else if (line.trim().startsWith('- ') || line.trim().startsWith('• ')) {
        final content = line.trim().substring(2);
        lineWidgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Expanded(
                  child: _parseFormattedSpans(content, isDark),
                ),
              ],
            ),
          ),
        );
      } else {
        lineWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _parseFormattedSpans(line, isDark),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lineWidgets,
    );
  }

  Widget _parseFormattedSpans(String text, bool isDark) {
    // Parses **bold** segments
    final spans = <TextSpan>[];
    final parts = text.split('**');

    for (int i = 0; i < parts.length; i++) {
      final isBold = i % 2 == 1;
      spans.add(
        TextSpan(
          text: parts[i],
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w400,
            color: isBold
                ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
            fontSize: 13.5,
            height: 1.45,
          ),
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
