import 'package:flutter/material.dart';

class SearchableBankDropdown extends StatefulWidget {
  final List<Map<String, dynamic>> banks;
  final String? value;
  final Function(String?) onChanged;
  final String? Function(String?)? validator;
  final String labelText;
  final String helperText;

  const SearchableBankDropdown({
    Key? key,
    required this.banks,
    required this.value,
    required this.onChanged,
    this.validator,
    this.labelText = 'Select Bank',
    this.helperText = 'Choose your bank',
  }) : super(key: key);

  @override
  State<SearchableBankDropdown> createState() => _SearchableBankDropdownState();
}

class _SearchableBankDropdownState extends State<SearchableBankDropdown> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  bool _isOpen = false;
  List<Map<String, dynamic>> _filteredBanks = [];
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _filteredBanks = widget.banks;
    
    // Set initial text if there's a selected value
    if (widget.value != null) {
      final selectedBank = widget.banks.firstWhere(
        (bank) => bank['id'].toString() == widget.value,
        orElse: () => {'name': ''},
      );
      _searchController.text = selectedBank['name']?.toString() ?? '';
    }
    
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _hideOverlay();
      }
    });
  }

  @override
  void didUpdateWidget(SearchableBankDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update filtered banks when the bank list changes
    if (widget.banks != oldWidget.banks) {
      setState(() {
        _filteredBanks = widget.banks;
      });
    }
    
    // Update text controller when value changes
    if (widget.value != oldWidget.value) {
      final selectedBank = widget.banks.firstWhere(
        (bank) => bank['id'].toString() == widget.value,
        orElse: () => {'name': ''},
      );
      _searchController.text = selectedBank['name']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _hideOverlay();
    super.dispose();
  }

  void _filterBanks(String query) {
    setState(() {
      _filteredBanks = widget.banks.where((bank) {
        return bank['name'].toString().toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
    _updateOverlay();
  }

  void _showOverlay() {
    _isOpen = true;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _isOpen = false;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 5.0),
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 200,
                minWidth: size.width,
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _filteredBanks.length,
                itemBuilder: (context, index) {
                  final bank = _filteredBanks[index];
                  return ListTile(
                    dense: true,
                    title: Text(bank['name']),
                    selected: widget.value == bank['id'].toString(),
                    onTap: () {
                      setState(() {
                        widget.onChanged(bank['id'].toString());
                        _searchController.text = bank['name'];
                        _hideOverlay();
                        _focusNode.unfocus();
                        _isOpen = false;
                      });
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: widget.validator,
      initialValue: widget.value,
      builder: (FormFieldState<String> field) {
        return CompositedTransformTarget(
          link: _layerLink,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  if (_isOpen) {
                    _hideOverlay();
                    _focusNode.unfocus();
                  } else {
                    _filterBanks('');
                    _showOverlay();
                  }
                },
                child: TextFormField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  readOnly: true,
                  enabled: true,
                  decoration: InputDecoration(
                    labelText: widget.labelText,
                    helperText: widget.helperText,
                    prefixIcon: const Icon(Icons.account_balance),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                widget.onChanged(null);
                                _hideOverlay();
                                _focusNode.unfocus();
                                _isOpen = false;
                              });
                            },
                          ),
                        IconButton(
                          icon: Icon(_isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down),
                          onPressed: () {
                            if (_isOpen) {
                              _hideOverlay();
                              _focusNode.unfocus();
                            } else {
                              _filterBanks('');
                              _showOverlay();
                            }
                          },
                        ),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              if (field.hasError)
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 8),
                  child: Text(
                    field.errorText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
} 