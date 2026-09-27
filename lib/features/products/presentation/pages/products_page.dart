import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lazy_load_scrollview/lazy_load_scrollview.dart';

import '../../../../core/di/di_exports.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/load_state_views.dart';
import '../../../../core/widgets/locale_change_listener.dart';
import '../../../../core/widgets/screen_header.dart';
import '../cubit/products_cubit.dart';
import '../cubit/products_state.dart';
import '../widgets/product_row.dart';
import '../widgets/product_search_bar.dart';

/// V05 — the catalogue: stock on every row, publishing as one switch, and
/// the way into a new product.
class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProductsCubit>()..load(),
      child: const _ProductsView(),
    );
  }
}

class _ProductsView extends StatelessWidget {
  const _ProductsView();

  /// Opens the editor — for [id], or a new product — and reads the list
  /// again when it saved something.
  Future<void> _openEditor(BuildContext context, [String? id]) async {
    final saved = await context.push<bool>(
      id == null ? AppRoutes.newProduct : AppRoutes.product(id),
    );
    if (saved == true && context.mounted) {
      context.read<ProductsCubit>().load(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProductsCubit>();

    return LocaleChangeListener(
      onChanged: () => cubit.load(refresh: true),
      child: Scaffold(
        body: Column(
          children: [
            ScreenHeader(
              kicker: 'kicker_products'.tr(),
              title: 'title_products'.tr(),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 12.h),
              child: ProductSearchBar(
                onChanged: cubit.search,
                onAdd: () => _openEditor(context),
              ),
            ),
            Expanded(
              child: BlocConsumer<ProductsCubit, ProductsState>(
                listenWhen: (previous, current) =>
                    current.errorMessage != null &&
                    current.errorMessage != previous.errorMessage,
                listener: (context, state) {
                  if (state.hasContent) {
                    showAppToast(context, state.errorMessage!, isError: true);
                  }
                },
                builder: _buildList,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, ProductsState state) {
    final cubit = context.read<ProductsCubit>();

    if (state.status == ProductsStatus.error) {
      return LoadErrorView(
        message: state.errorMessage ?? 'products_failed'.tr(),
        onRetry: cubit.load,
      );
    }
    if (!state.hasContent) return const LoadingView();

    return RefreshIndicator(
      onRefresh: () => cubit.load(refresh: true),
      child: LazyLoadScrollView(
        isLoading: state.isLoadingMore,
        onEndOfPage: cubit.loadMore,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            if (state.products.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                  icon: AppIcons.navProducts,
                  message: state.query.isEmpty
                      ? 'products_empty'.tr()
                      : 'products_no_match'.tr(args: [state.query]),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                sliver: SliverList.separated(
                  itemCount: state.products.length,
                  separatorBuilder: (_, _) => SizedBox(height: 10.h),
                  itemBuilder: (context, index) {
                    final product = state.products[index];
                    return ProductRow(
                      product: product,
                      toggling: state.togglingIds.contains(product.id),
                      onTap: () => _openEditor(context, product.id),
                      onToggle: () => cubit.toggleVisibility(product),
                    );
                  },
                ),
              ),
            if (state.isLoadingMore)
              const SliverToBoxAdapter(child: LoadingView()),
          ],
        ),
      ),
    );
  }
}
