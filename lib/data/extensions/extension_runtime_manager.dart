import 'package:flutter/material.dart';
import 'package:metia/data/extensions/extension_services.dart';
import 'package:metia/js_core/script_executor.dart';
import 'package:metia/models/logger.dart';

class ExtensionRuntimeManager extends ChangeNotifier {
  final ExtensionServices extensionServices;

  // Single executor instance shared among all main extensions
  ScriptExecutor? _executor;

  // Notifier to indicate when executor is ready
  final ValueNotifier<bool> ready = ValueNotifier(false);

  // Track current main extension id
  int? _currentMainId;

  ExtensionRuntimeManager(this.extensionServices) {
    // Listen for changes in the extensions list
    extensionServices.addListener(_onExtensionsChanged);
  }

  ScriptExecutor? get executor => _executor;

  /// Initialize the executor for the current main extension
  Future<void> init() async {
    _executor ??= await ScriptExecutor.create();
    await _loadCurrentMainExtension();
    ready.value = true;
    
    notifyListeners();
  }

  /// Detect main extension change and load it automatically
  Future<void> _onExtensionsChanged() async {
    final mainExt = extensionServices.mainExtension;
    if (mainExt == null) return;

    // Only reload if main extension actually changed
    if (_currentMainId != mainExt.id) {
      _currentMainId = mainExt.id;
      ready.value = false;
      notifyListeners();

      await _loadCurrentMainExtension();

      ready.value = true;
      notifyListeners();
    }
  }

  /// Load JS code for the current main extension
  Future<void> _loadCurrentMainExtension() async {
    final mainExt = extensionServices.mainExtension;
    if (mainExt == null || _executor == null) return;

    // Just load the new JS code
    await _executor!.loadExtension(mainExt.jsCode ?? "");
    Logger.log("${mainExt.name} is loaded!");
  }

  @override
  void dispose() {
    _executor?.dispose();
    ready.dispose();
    extensionServices.removeListener(_onExtensionsChanged);
    super.dispose();
  }
}
