import 'dart:math';

import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/order/domain/entities/order_entity.dart';
import 'package:flow_pos/features/order/domain/entities/order_item.dart';
import 'package:flow_pos/features/order/domain/repositories/order_repository.dart';
import 'package:fpdart/fpdart.dart';

class CreateOrder implements UseCase<OrderEntity, CreateOrderParams> {
  final OrderRepository orderRepository;

  const CreateOrder(this.orderRepository);

  static const Set<String> supportedMethods = {'QRIS', 'CASH', 'NONE'};

  @override
  Future<Either<Failure, OrderEntity>> call(CreateOrderParams params) async {
    final normalizedMethod = params.method.trim().toUpperCase();

    if (!supportedMethods.contains(normalizedMethod)) {
      return left(const Failure('Payment method must be QRIS or CASH.'));
    }

    if (params.items.isEmpty) {
      return left(const Failure('Order items cannot be empty.'));
    }

    if (params.tableNumber < 0) {
      return left(const Failure('Table number must be at least 0.'));
    }

    if (params.subtotal < 0 || params.total < 0) {
      return left(const Failure('Subtotal and total must be non-negative.'));
    }

    if (params.total < params.subtotal) {
      return left(const Failure('Total cannot be less than subtotal.'));
    }

    if (params.tax < 0 || params.serviceCharge < 0) {
      return left(
        const Failure('Tax and service charge must be non-negative.'),
      );
    }

    final hasInvalidItem = params.items.any(
      (item) => item.quantity <= 0 || item.unitPrice < 0,
    );
    if (hasInvalidItem) {
      return left(
        const Failure(
          'Item quantity must be greater than 0 and unit price must be non-negative.',
        ),
      );
    }

    if (normalizedMethod == 'QRIS' &&
        params.status != 'UNPAID' &&
        params.amountPaid != params.total) {
      return left(const Failure('For QRIS, amount paid must equal total.'));
    }

    if (normalizedMethod == 'CASH' && params.amountPaid < params.total) {
      return left(
        const Failure('For CASH, amount paid cannot be less than total.'),
      );
    }

    if (normalizedMethod == 'NONE' && params.status != 'UNPAID') {
      return left(
        const Failure('For payment method NONE, order status must be UNPAID.'),
      );
    }

    final safeAmountPaid = max(params.amountPaid, 0);

    return await orderRepository.createOrder(
      orderNumber: params.orderNumber,
      tableNumber: params.tableNumber,
      cashierId: params.cashierId,
      subtotal: params.subtotal,
      tax: params.tax,
      serviceCharge: params.serviceCharge,
      total: params.total,
      method: normalizedMethod,
      amountPaid: safeAmountPaid,
      items: params.items,
      shiftId: params.shiftId,
      status: params.status,
      customerName: params.customerName,
      paymentLink: params.paymentLink,
    );
  }
}

class CreateOrderParams {
  final String orderNumber;
  final int tableNumber;
  final String cashierId;
  final int subtotal;
  final double tax;
  final double serviceCharge;
  final int total;
  final String method;
  final int amountPaid;
  final List<OrderItem> items;
  final String? shiftId;
  final String status;
  final String? customerName;
  final String? paymentLink;

  const CreateOrderParams({
    required this.orderNumber,
    required this.tableNumber,
    required this.cashierId,
    required this.subtotal,
    required this.tax,
    required this.serviceCharge,
    required this.total,
    required this.method,
    required this.amountPaid,
    required this.items,
    this.shiftId,
    this.status = 'UNPAID',
    this.customerName,
    this.paymentLink,
  });
}
