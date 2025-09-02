import 'package:flutter/material.dart';

class CustomSoftKeyboard extends StatefulWidget {
  final Function(String) onKeyTap; // Callback for key taps
  final VoidCallback? onDelete;   // Callback for delete action
  final VoidCallback? onSubmit;   // Callback for submit action
  final VoidCallback? onDismiss; // Callback for dismiss action
  final String description;      // Description to display at the top of the keyboard
  final bool isObscured;         // Dynamically control text visibility
  final String submitBtnLabel;   // Dynamically label the Submit button
  final Color submitBtnBgColor;   // Dynamically change bgColor for the Submit button
  final Color submitBtnTxColor;   // Dynamically change textColor for the Submit button

  const CustomSoftKeyboard({
    Key? key,
    required this.onKeyTap,
    this.onDelete,
    this.onSubmit,
    this.onDismiss,
    this.submitBtnLabel = "Submit",
    this.submitBtnTxColor = Colors.white,
    this.submitBtnBgColor = Colors.green,
    this.description = "Secured keyboard",
    this.isObscured = false,
  }) : super(key: key);

  @override
  _CustomSoftKeyboardState createState() => _CustomSoftKeyboardState();
}

class _CustomSoftKeyboardState extends State<CustomSoftKeyboard> {
  String input = ""; // Stores the input text
  late bool isObscured; // Internal state to track visibility

  @override
  void initState() {
    super.initState();
    isObscured = widget.isObscured; // Initialize with external value
  }

  void _handleKeyTap(String value) {
    if (mounted) {
      setState(() {
        input += value; // Append key value to input
        widget.onKeyTap(input);
      });      
    }
  }

  void _handleDelete() {
    if (mounted) {
      setState(() {
        if (input.isNotEmpty) {
          input = input.substring(0, input.length - 1); // Remove last character
          widget.onKeyTap(input);
        }
      });
    }
  }

  void _toggleVisibility() {
    if (mounted) {
      setState(() {
        isObscured = !isObscured; // Toggle between hashed and visible text
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              
              // Description
              if (widget.description.isNotEmpty)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Text(
                      widget.description,
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

              // Dismiss Button as "Close" or "Dismiss"
              TextButton(
                onPressed: widget.onDismiss, // Trigger dismiss callback
                child: const Text(
                  "Close", // Or "Dismiss"
                  style: TextStyle(color: Colors.red, fontSize: 18.0),
                ),
              ),

            ],
          ),
        ),



        // Display Text Field with Toggle Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Display the input (hashed or visible)
              Expanded(
                child: Text(
                  isObscured ? '*' * input.length : input,
                  style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                ),
              ),
              // Toggle Button
              IconButton(
                icon: Icon(
                  isObscured ? Icons.visibility_off : Icons.visibility,
                  color: Colors.blue,
                ),
                onPressed: _toggleVisibility,
              ),
            ],
          ),
        ),
        // Keyboard Grid
        Container(
          padding: const EdgeInsets.all(8.0),
          color: Colors.white, // Keeping background separate from input
          child: GridView.builder(
            shrinkWrap: true,
            itemCount: 12, // 0-9 + delete + submit
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.0,
            ),
            itemBuilder: (context, index) {
              if (index < 9) {
                // Numbers 1-9
                return _buildKey(
                  text: (index + 1).toString(),
                  onTap: () => _handleKeyTap((index + 1).toString()),
                );
              }
              switch (index) {
                case 9: // Submit Button
                  return _buildKey(
                    text: widget.submitBtnLabel,
                    onTap: widget.onSubmit, // Trigger submit callback
                    textColor: widget.submitBtnTxColor,
                    bgColor: widget.submitBtnBgColor,
                  );
                case 10: // 0 key
                  return _buildKey(
                    text: "0",
                    onTap: () => _handleKeyTap("0"),
                  );
                case 11: // Delete key
                  return _buildKey(
                    icon: Icons.backspace_outlined,
                    onTap: _handleDelete,
                    textColor: Colors.white,
                    bgColor: Colors.red,
                  );
                default:
                  return const SizedBox.shrink();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildKey({
    String? text,
    Color? bgColor,
    IconData? icon,
    VoidCallback? onTap,
    Color textColor = Colors.black,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: bgColor ?? Colors.grey[200]!,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Center(
          child: text != null
          ? Text(
            text,
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center, // Center the text within its container
          ) : Icon(icon, size: 24.0, color: textColor),
        ),
      ),
    );
  }
}
