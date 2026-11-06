import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stitchcraft/core/services/auth_service.dart';
import 'package:stitchcraft/core/services/local_db_service.dart';
import 'package:stitchcraft/core/repositories/order_repository.dart';
import 'package:stitchcraft/core/theme/app_theme.dart';
import 'package:stitchcraft/core/widgets/primary_button.dart';

class OutsourceOrderSheet extends StatefulWidget {
  final Map<String, dynamic> order;
  final Function(Map<String, dynamic> updatedOrder) onUpdated;

  const OutsourceOrderSheet({
    super.key,
    required this.order,
    required this.onUpdated,
  });

  @override
  State<OutsourceOrderSheet> createState() => _OutsourceOrderSheetState();
}

class _OutsourceOrderSheetState extends State<OutsourceOrderSheet> {
  final _authService = AuthService();
  final _localDb = LocalDatabaseService();

  final _searchController = TextEditingController();
  final _manualShopNameController = TextEditingController();
  final _manualPhoneController = TextEditingController();
  final _agreedCostController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isManualInput = false;

  List<Map<String, dynamic>> _partnerTailors = [];
  Map<String, dynamic>? _selectedTailor;

  @override
  void initState() {
    super.initState();
    _fetchPartnerTailors();
    final existingCost = widget.order['delegated_cost'] ?? widget.order['delegatedCost'];
    if (existingCost != null && (existingCost as num) > 0) {
      _agreedCostController.text = existingCost.toString();
    }
    final existingNotes = widget.order['delegated_notes'] ?? widget.order['delegatedNotes'];
    if (existingNotes != null && existingNotes.toString().isNotEmpty) {
      _notesController.text = existingNotes.toString();
    }
  }

  @override
  void dispose() {
    final searchCtrl = _searchController;
    final manualShopCtrl = _manualShopNameController;
    final manualPhoneCtrl = _manualPhoneController;
    final agreedCostCtrl = _agreedCostController;
    final notesCtrl = _notesController;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      searchCtrl.dispose();
      manualShopCtrl.dispose();
      manualPhoneCtrl.dispose();
      agreedCostCtrl.dispose();
      notesCtrl.dispose();
    });
    super.dispose();
  }

  bool get _isCurrentlyDelegated {
    final status = widget.order['delegation_status'] ?? widget.order['delegationStatus'];
    final targetShop = widget.order['delegated_to_shop_name'] ??
        widget.order['delegatedToShopName'] ??
        widget.order['delegated_to_shop_id'] ??
        widget.order['delegatedToShopId'];
    return (status == 'assigned' || status == 'completed') &&
        targetShop != null &&
        targetShop.toString().isNotEmpty;
  }

  bool get _isOrderCompleted {
    final status = (widget.order['status'] ?? '').toString().toLowerCase();
    return status == 'completed' || status == 'delivered' || status == 'ready' || status == 'cancelled';
  }

  Future<void> _fetchPartnerTailors([String query = '']) async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      if (token != null) {
        final uri = Uri.parse('${AuthService.baseUrl}/shops/partners')
            .replace(queryParameters: query.isNotEmpty ? {'query': query} : null);
        final response = await http.get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final decoded = json.decode(response.body);
          if (decoded is List) {
            if (mounted) {
              setState(() {
                _partnerTailors = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
                _isLoading = false;
              });
              return;
            }
          }
        }
      }
    } catch (e) {
      developer.log('Error fetching partner tailors: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleDelegate() async {
    if (_isOrderCompleted) {
      _showSnack('Cannot outsource an order that is already completed or cancelled', AppTheme.alertRed);
      return;
    }

    String targetShopId = '';
    String targetShopName = '';
    String targetPhone = '';

    if (_isManualInput) {
      targetShopName = _manualShopNameController.text.trim();
      targetPhone = _manualPhoneController.text.trim();
      if (targetShopName.isEmpty) {
        _showSnack('Please enter tailor or shop name', AppTheme.alertRed);
        return;
      }
      targetShopId = 'partner_${targetPhone.replaceAll(RegExp(r'\D'), '')}';
    } else {
      if (_selectedTailor == null) {
        _showSnack('Please select a tailor from the list or use manual input', AppTheme.alertRed);
        return;
      }
      targetShopId = (_selectedTailor!['_id'] ?? _selectedTailor!['id'] ?? '').toString();
      targetShopName = (_selectedTailor!['shopName'] ?? _selectedTailor!['name'] ?? 'Partner Tailor').toString();
      targetPhone = (_selectedTailor!['phone'] ?? '').toString();
    }

    final orderId = (widget.order['id'] ?? widget.order['_id'] ?? '').toString();
    final notes = _notesController.text.trim();
    final agreedCost = double.tryParse(_agreedCostController.text.trim()) ?? 0.0;

    if (agreedCost <= 0) {
      _showSnack('Please enter a valid agreed outsourcing cost (₹)', AppTheme.alertRed);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final token = await _authService.getToken();
      Map<String, dynamic>? updatedFromServer;

      if (token != null) {
        final resp = await http.post(
          Uri.parse('${AuthService.baseUrl}/orders/$orderId/delegate'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({
            'targetShopId': targetShopId,
            'targetShopName': targetShopName,
            'targetPhone': targetPhone,
            'notes': notes,
            'agreedCost': agreedCost,
          }),
        ).timeout(const Duration(seconds: 10));

        if (resp.statusCode == 200) {
          updatedFromServer = json.decode(resp.body) as Map<String, dynamic>?;
        }
      }

      // Update local SQLite
      final now = DateTime.now().millisecondsSinceEpoch;
      final localUpdate = {
        'delegated_to_shop_id': targetShopId,
        'delegated_to_shop_name': targetShopName,
        'delegated_to_phone': targetPhone,
        'delegation_status': 'assigned',
        'delegated_notes': notes,
        'delegated_cost': agreedCost,
        'sync_status': 3,
        'updated_at': now,
      };

      try {
        await OrderRepository().updateOrder(orderId, localUpdate);
      } catch (e) {
        developer.log('Local delegate update error: $e');
      }

      final mergedOrder = Map<String, dynamic>.from(widget.order);
      mergedOrder.addAll(updatedFromServer ?? localUpdate);
      mergedOrder['delegated_to_shop_name'] = targetShopName;
      mergedOrder['delegatedToShopName'] = targetShopName;
      mergedOrder['delegation_status'] = 'assigned';
      mergedOrder['delegationStatus'] = 'assigned';
      mergedOrder['delegated_notes'] = notes;
      mergedOrder['delegatedNotes'] = notes;
      mergedOrder['delegated_cost'] = agreedCost;
      mergedOrder['delegatedCost'] = agreedCost;

      widget.onUpdated(mergedOrder);

      if (mounted) {
        Navigator.pop(context);
        _showSnack(
          'Order successfully outsourced to $targetShopName! Partner tailor notified.',
          AppTheme.trustGreen,
        );
      }
    } catch (err) {
      developer.log('Delegation error: $err');
      _showSnack('Error delegating order: $err', AppTheme.alertRed);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleRevoke() async {
    if (_isOrderCompleted) {
      _showSnack('Cannot recall an order that is already completed or cancelled', AppTheme.alertRed);
      return;
    }

    final orderId = (widget.order['id'] ?? widget.order['_id'] ?? '').toString();
    setState(() => _isSubmitting = true);

    try {
      final token = await _authService.getToken();
      if (token != null) {
        await http.post(
          Uri.parse('${AuthService.baseUrl}/orders/$orderId/revoke-delegation'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 8));
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final localUpdate = {
        'delegated_to_shop_id': null,
        'delegated_to_shop_name': null,
        'delegated_to_phone': null,
        'delegation_status': 'none',
        'delegated_notes': null,
        'sync_status': 3,
        'updated_at': now,
      };

      try {
        await OrderRepository().updateOrder(orderId, localUpdate);
      } catch (_) {}

      final mergedOrder = Map<String, dynamic>.from(widget.order);
      mergedOrder['delegated_to_shop_name'] = null;
      mergedOrder['delegatedToShopName'] = null;
      mergedOrder['delegation_status'] = 'none';
      mergedOrder['delegationStatus'] = 'none';
      mergedOrder['delegated_notes'] = null;

      widget.onUpdated(mergedOrder);

      if (mounted) {
        Navigator.pop(context);
        _showSnack('Delegation recalled. Order returned to in-house shop.', AppTheme.brandPurple);
      }
    } catch (e) {
      _showSnack('Error revoking delegation: $e', AppTheme.alertRed);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final customerName = widget.order['customer_name'] ?? widget.order['customerName'] ?? 'Customer';
    final garment = widget.order['garment_type'] ?? widget.order['apparelType'] ?? widget.order['item_types'] ?? 'Garment';
    final displayId = (widget.order['orderId'] ?? widget.order['id'] ?? widget.order['_id'] ?? '').toString();
    final shortId = displayId.length > 8 ? displayId.substring(0, 8) : displayId;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Outsource to Partner Tailor',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Order #$shortId • $customerName ($garment)',
                      style: const TextStyle(
                        color: AppTheme.darkGrey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // If currently delegated, display active assignment banner
          if (_isCurrentlyDelegated) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.brandPurple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.brandPurple.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.handshake_outlined, color: AppTheme.brandPurple, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Currently Outsourced To:',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.brandPurple,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ACTIVE JOB',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (widget.order['delegated_to_shop_name'] ?? widget.order['delegatedToShopName'] ?? 'Partner Shop').toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (widget.order['delegated_to_phone'] != null && widget.order['delegated_to_phone'].toString().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Phone: ${widget.order['delegated_to_phone']}',
                      style: const TextStyle(color: AppTheme.darkGrey, fontSize: 12),
                    ),
                  ],
                  if (widget.order['delegated_cost'] != null || widget.order['delegatedCost'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Agreed Partner Cost: ₹${widget.order['delegated_cost'] ?? widget.order['delegatedCost']}',
                      style: const TextStyle(color: AppTheme.trustGreen, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                  if (widget.order['delegated_notes'] != null && widget.order['delegated_notes'].toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Instructions: "${widget.order['delegated_notes']}"',
                      style: const TextStyle(color: AppTheme.darkGrey, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (!_isOrderCompleted) ...[
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.alertRed,
                  side: const BorderSide(color: AppTheme.alertRed),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isSubmitting ? null : _handleRevoke,
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: Text(_isSubmitting ? 'Recalling...' : 'Recall Order to My Shop (પાછો ખેંચો)'),
              ),
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Or Reassign to Another Partner Tailor:',
                style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface, fontSize: 14),
              ),
              const SizedBox(height: 8),
            ],
          ],

          if (_isOrderCompleted)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkBg : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppTheme.trustGreen, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'This order has reached its final state and can no longer be outsourced or reassigned.',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Toggle Search Network vs Manual Phone Input
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Partner Network'),
                    selected: !_isManualInput,
                    onSelected: (val) => setState(() => _isManualInput = !val),
                    selectedColor: AppTheme.brandPurple.withValues(alpha: 0.18),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Direct Phone Number'),
                    selected: _isManualInput,
                    onSelected: (val) => setState(() => _isManualInput = val),
                    selectedColor: AppTheme.brandPurple.withValues(alpha: 0.18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Search or Manual Inputs
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_isManualInput) ...[
                      // Search partner tailors
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search tailor by shop name or phone...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _fetchPartnerTailors();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (val) => _fetchPartnerTailors(val),
                      ),
                      const SizedBox(height: 10),

                      if (_isLoading)
                        const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                      else if (_partnerTailors.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkBg : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.storefront_outlined, color: AppTheme.darkGrey, size: 36),
                              const SizedBox(height: 6),
                              const Text(
                                'No registered partner tailors found.',
                                style: TextStyle(color: AppTheme.darkGrey, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              TextButton(
                                onPressed: () => setState(() => _isManualInput = true),
                                child: const Text('Enter Partner Phone Directly →'),
                              ),
                            ],
                          ),
                        )
                      else
                        ...List.generate(_partnerTailors.length, (idx) {
                          final tailor = _partnerTailors[idx];
                          final isSelected = _selectedTailor != null &&
                              (_selectedTailor!['_id'] ?? _selectedTailor!['id']) ==
                                  (tailor['_id'] ?? tailor['id']);
                          final shopName = tailor['shopName'] ?? 'Tailor Shop';
                          final phone = tailor['phone'] ?? '';
                          final address = tailor['address'] ?? '';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () => setState(() => _selectedTailor = tailor),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.brandPurple.withValues(alpha: 0.15)
                                      : (isDark ? AppTheme.darkBg : Colors.grey.shade100),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? AppTheme.brandPurple : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppTheme.brandPurple.withValues(alpha: 0.2),
                                      child: const Icon(Icons.store, color: AppTheme.brandPurple, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            shopName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.onSurface,
                                            ),
                                          ),
                                          if (phone.isNotEmpty)
                                            Text(
                                              phone,
                                              style: const TextStyle(color: AppTheme.darkGrey, fontSize: 12),
                                            ),
                                          if (address.isNotEmpty)
                                            Text(
                                              address,
                                              style: const TextStyle(color: AppTheme.darkGrey, fontSize: 11),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(Icons.check_circle, color: AppTheme.brandPurple),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                    ] else ...[
                      // Manual Direct Input
                      TextField(
                        controller: _manualShopNameController,
                        decoration: InputDecoration(
                          labelText: 'Partner Tailor / Shop Name *',
                          hintText: 'e.g. Ramesh Tailors',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _manualPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Partner Tailor Phone Number *',
                          hintText: 'e.g. 9876543210',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    // Agreed Outsourcing Cost (₹)
                    TextField(
                      controller: _agreedCostController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Agreed Outsourcing Cost / Rate (₹) * (સોંપવાનો ભાવ)',
                        hintText: 'e.g. 500 (Payable to partner tailor)',
                        prefixIcon: const Icon(Icons.currency_rupee, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Tailoring instructions / notes for the partner
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Instructions for Partner Tailor (વિશેષ સૂચના)',
                        hintText: 'e.g. Please finish collar and sleeves first, urgent delivery...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Submit Button
            PrimaryButton(
              text: _isSubmitting
                  ? 'Assigning Order...'
                  : (_isCurrentlyDelegated ? 'Reassign to This Tailor' : 'Give Order to Tailor (ઓર્ડર સોંપો)'),
              onPressed: _isSubmitting ? () {} : _handleDelegate,
              isLoading: _isSubmitting,
            ),
          ],
        ],
      ),
    );
  }
}

