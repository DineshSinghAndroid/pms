import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../bloc/news_tracking/news_tracking_bloc.dart';
import '../../bloc/news_tracking/news_tracking_event.dart';
import '../../models/newspaper_entry_model.dart';
import '../../models/newspaper_model.dart';
import '../../models/newspaper_size_model.dart';
import '../../models/wing_model.dart';
import '../../theme/pms_theme.dart';

class AddEditNewspaperEntryDialog extends StatefulWidget {
  final NewspaperEntryModel? entry;
  final List<WingModel> wings;
  final List<NewspaperModel> newspapers;
  final List<NewspaperSizeModel> sizes;
  final String? phone;

  const AddEditNewspaperEntryDialog({
    super.key,
    this.entry,
    required this.wings,
    required this.newspapers,
    required this.sizes,
    this.phone,
  });

  @override
  State<AddEditNewspaperEntryDialog> createState() =>
      _AddEditNewspaperEntryDialogState();
}

class _AddEditNewspaperEntryDialogState
    extends State<AddEditNewspaperEntryDialog> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedWingId;
  int? _selectedNewspaperId;
  int? _selectedSizeId;
  DateTime _publishDate = DateTime.now();

  late final TextEditingController _adNameController;
  late final TextEditingController _link1Controller;
  late final TextEditingController _link2Controller;
  late final TextEditingController _remarkController;

  String? _pickedFilePath;
  String? _pickedFileName;
  bool _isSaving = false;

  bool get isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _selectedWingId = e?.wingId;
    _selectedNewspaperId = e?.newspaperId;
    _selectedSizeId = e?.newspaperSizeId;

    if (e?.publishDate != null && e!.publishDate.isNotEmpty) {
      _publishDate = DateTime.tryParse(e.publishDate) ?? DateTime.now();
    }

    _adNameController = TextEditingController(text: e?.adName ?? '');
    _link1Controller = TextEditingController(text: e?.link1 ?? '');
    _link2Controller = TextEditingController(text: e?.link2 ?? '');
    _remarkController = TextEditingController(text: e?.remark ?? '');
  }

  @override
  void dispose() {
    _adNameController.dispose();
    _link1Controller.dispose();
    _link2Controller.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.any,
      );
      if (file != null) {
        setState(() {
          _pickedFilePath = file.path;
          _pickedFileName = file.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _publishDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF059669),
              onPrimary: Colors.white,
              onSurface: PmsTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _publishDate = picked;
      });
    }
  }

  void _showQuickNewspaperDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Add Newspaper Publication',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Times of India, Dainik Navjyoti',
            labelText: 'Publication Name *',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(dialogCtx);
                context.read<NewsTrackingBloc>().add(
                  CreateNewspaperMasterEvent(name: name, phone: widget.phone),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showQuickSizeDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Add Ad Dimensions / Size',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. 52*33, 45*33, Power Jacket',
            labelText: 'Ad Size Name *',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(dialogCtx);
                context.read<NewsTrackingBloc>().add(
                  CreateSizeMasterEvent(name: name, phone: widget.phone),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _saveEntry() {
    if (!_formKey.currentState!.validate()) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(_publishDate);
    final adName = _adNameController.text.trim();
    final link1 = _link1Controller.text.trim();
    final link2 = _link2Controller.text.trim();
    final remark = _remarkController.text.trim();

    setState(() => _isSaving = true);

    if (isEditing) {
      context.read<NewsTrackingBloc>().add(
        UpdateNewsEntryEvent(
          id: widget.entry!.id,
          adName: adName,
          publishDate: dateStr,
          wingId: _selectedWingId,
          newspaperId: _selectedNewspaperId,
          newspaperSizeId: _selectedSizeId,
          link1: link1.isNotEmpty ? link1 : null,
          link2: link2.isNotEmpty ? link2 : null,
          remark: remark.isNotEmpty ? remark : null,
          localFilePath: _pickedFilePath,
          phone: widget.phone,
        ),
      );
    } else {
      context.read<NewsTrackingBloc>().add(
        CreateNewsEntryEvent(
          adName: adName,
          publishDate: dateStr,
          wingId: _selectedWingId,
          newspaperId: _selectedNewspaperId,
          newspaperSizeId: _selectedSizeId,
          link1: link1.isNotEmpty ? link1 : null,
          link2: link2.isNotEmpty ? link2 : null,
          remark: remark.isNotEmpty ? remark : null,
          localFilePath: _pickedFilePath,
          phone: widget.phone,
        ),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 700),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.newspaper_rounded,
                      color: Color(0xFF059669),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing
                              ? 'Edit News Advertisement'
                              : 'Add News Advertisement',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: PmsTheme.textPrimary,
                          ),
                        ),
                        const Text(
                          'Track ad campaigns, dimensions & clippings',
                          style: TextStyle(fontSize: 11, color: PmsTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Form fields
              Expanded(
                child: ListView(
                  children: [
                    // Campus Wing & Publish Date
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _selectedWingId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Campus Wing *',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: widget.wings
                                .map(
                                  (w) => DropdownMenuItem(
                                    value: w.id,
                                    child: Text(
                                      w.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _selectedWingId = v),
                            validator: (v) =>
                                v == null ? 'Wing required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _selectDate,
                            borderRadius: BorderRadius.circular(10),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Publish Date *',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                suffixIcon: Icon(Icons.calendar_today_rounded, size: 16),
                              ),
                              child: Text(
                                dateFormat.format(_publishDate),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Newspaper Publication
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _selectedNewspaperId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Newspaper Publication *',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: widget.newspapers
                                .map(
                                  (n) => DropdownMenuItem(
                                    value: n.id,
                                    child: Text(
                                      n.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _selectedNewspaperId = v),
                            validator: (v) =>
                                v == null ? 'Publication required' : null,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Color(0xFF059669)),
                          tooltip: 'Add New Publication',
                          onPressed: _showQuickNewspaperDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Ad Dimensions / Size
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _selectedSizeId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Dimensions / Ad Size *',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: widget.sizes
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text(
                                      s.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _selectedSizeId = v),
                            validator: (v) =>
                                v == null ? 'Size required' : null,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Color(0xFF059669)),
                          tooltip: 'Add New Size',
                          onPressed: _showQuickSizeDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Ad Headline / Campaign Name
                    TextFormField(
                      controller: _adNameController,
                      decoration: const InputDecoration(
                        labelText: 'Ad Title / Headline / Campaign *',
                        hintText: 'e.g. 52x33-Editorial Page-2026 (All Rajasthan)',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Ad Title required' : null,
                    ),
                    const SizedBox(height: 14),

                    // e-Paper Links
                    TextFormField(
                      controller: _link1Controller,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'e-Paper Link 1 (Primary URL)',
                        hintText: 'https://...',
                        prefixIcon: Icon(Icons.link, size: 18),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _link2Controller,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'e-Paper Link 2 (Secondary URL)',
                        hintText: 'https://...',
                        prefixIcon: Icon(Icons.link_outlined, size: 18),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // File Attachment (AWS S3 Cloud Storage)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: PmsTheme.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: PmsTheme.glassBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Ad Clipping (AWS S3)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF334155),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: _pickFile,
                                icon: const Icon(Icons.upload_file, size: 14),
                                label: const Text('Browse File', style: TextStyle(fontSize: 11)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF059669),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                              ),
                            ],
                          ),
                          if (_pickedFileName != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: PmsTheme.glassSurface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF059669)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Color(0xFF059669), size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _pickedFileName!,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    onPressed: () {
                                      setState(() {
                                        _pickedFilePath = null;
                                        _pickedFileName = null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ] else if (widget.entry?.computedFileUrl != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Current file: ${widget.entry?.fileName ?? 'Attached File'}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Remarks
                    TextFormField(
                      controller: _remarkController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Remarks / Notes',
                        hintText: 'e.g. Shekhawati edition only, power jacket...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isSaving ? null : _saveEntry,
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            isEditing ? 'Save Changes' : 'Create Entry',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
