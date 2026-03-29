import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/demo_data_seeder.dart';
import '../../../../services/pro_service.dart';
import '../../../ideas/presentation/viewmodels/ideas_view_model.dart';
import '../../../health/presentation/viewmodels/habits_view_model.dart';
import '../../../work/presentation/viewmodels/projects_view_model.dart';
import '../../../work/presentation/viewmodels/standup_view_model.dart';
import '../../../family/presentation/viewmodels/contacts_view_model.dart';
import '../../../finance/presentation/viewmodels/finance_view_model.dart';
import '../../../family/presentation/viewmodels/family_viewmodel.dart';
import '../../../circles/presentation/viewmodels/circles_view_model.dart';
import '../../../../services/locale_service.dart';
import 'dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final _nameController = TextEditingController();
  final _storage = StorageService();
  int _currentPage = 0;

  void _next() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your name to continue')),
      );
      return;
    }
    await _storage.setUserName(name);

    // Always seed demo data — first impression of a populated app is everything
    await DemoDataSeeder.seedIfEmpty(_storage);

    // Start 30-day Pro trial
    final pro = ProService();
    await pro.init();
    await pro.startTrial();
    await _storage.setOnboardingDone();
    if (!mounted) return;

    // Reload all ViewModels so they pick up seeded data
    context.read<ProjectsViewModel>().reload();
    context.read<HabitsViewModel>().reload();
    context.read<IdeasViewModel>().reload();
    context.read<StandupViewModel>().reload();
    context.read<ContactsViewModel>().reload();
    context.read<FinanceViewModel>().reload();
    context.read<FamilyViewModel>().reload();
    context.read<CirclesViewModel>().reload();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.read<LocaleService>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              // Screen 1 — Identity + Pain
              _IntroPage(
                title: loc.t('ob_hook_title'),
                subtitle: loc.t('ob_hook_sub'),
                gradient: const [Color(0xFF0F172A), Color(0xFF1E40AF)],
                onNext: _next,
                buttonText: loc.t('continue_btn'),
              ),
              // Screen 2 — Promise + Proof
              _IntroPage(
                title: loc.t('ob_promise_title'),
                subtitle: loc.t('ob_promise_sub'),
                gradient: const [Color(0xFF581C87), Color(0xFFBE185D)],
                onNext: _next,
                buttonText: loc.t('ob_show_me'),
              ),
              // Screen 3 — Setup
              _SetupPage(
                nameController: _nameController,
                onFinish: _finish,
                loc: loc,
              ),
            ],
          ),
          // Page indicator dots
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == i ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == i
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  final String title, subtitle, buttonText;
  final List<Color> gradient;
  final VoidCallback onNext;

  const _IntroPage({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onNext,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 3),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 17,
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(flex: 4),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: gradient[0],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetupPage extends StatelessWidget {
  final TextEditingController nameController;
  final VoidCallback onFinish;
  final LocaleService loc;

  const _SetupPage({
    required this.nameController,
    required this.onFinish,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF065F46), Color(0xFF0F172A)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              Text(
                loc.t('ob_setup_title'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                loc.t('ob_setup_sub'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),

              // Name field
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  hintText: loc.t('name_hint'),
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  prefixIcon: Icon(Icons.person_outline, color: Colors.white.withValues(alpha: 0.5)),
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onFinish(),
              ),
              const SizedBox(height: 20),

              // Trial badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    const Text('', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loc.t('ob_trial_badge'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              // CTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onFinish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF065F46),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    loc.t('ob_cta'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  loc.t('ob_no_card'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
