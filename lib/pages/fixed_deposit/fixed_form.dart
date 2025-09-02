import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreatePlanPage extends StatefulWidget {
  const CreatePlanPage({super.key});

  @override
  State<CreatePlanPage> createState() => _CreatePlanPageState();
}

class _CreatePlanPageState extends State<CreatePlanPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _planNameController = TextEditingController();
  DateTime? _selectedDate;
  bool _disableInterest = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create your plan"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Savings amount (₦)"),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: '₦ ',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text.rich(
                    TextSpan(
                      text: "Available balance: ",
                      style: TextStyle(color: Colors.black54),
                      children: [
                        TextSpan(
                          text: "₦12,470.35",
                          style: TextStyle(
                            color: Color(0xFF7C3AED),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text("Give this plan a name (Optional)"),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _planNameController,
                    decoration: InputDecoration(
                      hintText: "Please enter",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text("Maturity Date"),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now().add(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 1000)),
                      );
                      if (pickedDate != null) {
                        setState(() => _selectedDate = pickedDate);
                      }
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: _selectedDate != null
                              ? DateFormat.yMMMd().format(_selectedDate!)
                              : "Set Maturity Date",
                          suffixIcon: const Icon(Icons.calendar_today),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Disable interest on your savings"),
                      Switch(
                        value: _disableInterest,
                        onChanged: (value) {
                          setState(() => _disableInterest = value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Next step logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBCA8F9), // Light purple
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Next", style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF9F9F9), // Light gray background
    );
  }
}
