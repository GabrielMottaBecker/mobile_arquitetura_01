import 'package:flutter/material.dart';
import '../../domain/entities/product.dart';
import '../viewmodels/product_viewmodel.dart';

/// Tela de formulário reutilizada para CADASTRO e EDIÇÃO de produtos.
///
/// Quando [product] é nulo → modo cadastro (POST).
/// Quando [product] é fornecido → modo edição (PUT).
class ProductFormPage extends StatefulWidget {
  final ProductViewModel viewModel;
  final Product? product; // null = cadastro, non-null = edição

  const ProductFormPage({
    super.key,
    required this.viewModel,
    this.product,
  });

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _imageCtrl;
  late final TextEditingController _categoryCtrl;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _titleCtrl = TextEditingController(text: p?.title ?? '');
    _priceCtrl =
        TextEditingController(text: p != null ? p.price.toString() : '');
    _descriptionCtrl = TextEditingController(text: p?.description ?? '');
    _imageCtrl = TextEditingController(text: p?.image ?? '');
    _categoryCtrl = TextEditingController(text: p?.category ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _descriptionCtrl.dispose();
    _imageCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  // ── Submissão ────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final product = Product(
      id: widget.product?.id,
      title: _titleCtrl.text.trim(),
      price: double.parse(_priceCtrl.text.trim()),
      description: _descriptionCtrl.text.trim(),
      image: _imageCtrl.text.trim(),
      category: _categoryCtrl.text.trim(),
      ratingRate: widget.product?.ratingRate ?? 0.0,
      ratingCount: widget.product?.ratingCount ?? 0,
    );

    bool success;
    if (_isEditing) {
      success = await widget.viewModel.updateProduct(product);
    } else {
      success = await widget.viewModel.createProduct(product);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      final msg = _isEditing
          ? 'Produto atualizado com sucesso!'
          : 'Produto cadastrado com sucesso!';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
      // Retorna o produto salvo para que a tela de detalhes possa se atualizar
      Navigator.pop(context, product);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao salvar produto. Tente novamente.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ── UI ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Editar Produto' : 'Novo Produto',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Preview da imagem
              if (_imageCtrl.text.isNotEmpty)
                _ImagePreview(url: _imageCtrl.text),

              const SizedBox(height: 16),

              _buildField(
                controller: _titleCtrl,
                label: 'Título do produto',
                icon: Icons.shopping_bag_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe o título' : null,
              ),
              const SizedBox(height: 14),

              _buildField(
                controller: _priceCtrl,
                label: 'Preço (R\$)',
                icon: Icons.attach_money,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Informe o preço';
                  if (double.tryParse(v.trim()) == null) {
                    return 'Valor numérico inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              _buildField(
                controller: _categoryCtrl,
                label: 'Categoria',
                icon: Icons.category_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe a categoria' : null,
              ),
              const SizedBox(height: 14),

              _buildField(
                controller: _imageCtrl,
                label: 'URL da imagem',
                icon: Icons.image_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe a URL da imagem' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),

              _buildField(
                controller: _descriptionCtrl,
                label: 'Descrição',
                icon: Icons.description_outlined,
                maxLines: 4,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe a descrição' : null,
              ),
              const SizedBox(height: 28),

              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(_isEditing ? Icons.save_outlined : Icons.add),
                  label: Text(
                    _isEditing ? 'Salvar alterações' : 'Cadastrar produto',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A1B9A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6A1B9A)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF6A1B9A), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final String url;
  const _ImagePreview({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image_outlined,
                size: 50, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}