class ApplicationState {
  final bool isSpyOn;

  ApplicationState({required this.isSpyOn});

  ApplicationState copyWith({bool? isSpyOn}) {
    return ApplicationState(isSpyOn: isSpyOn ?? this.isSpyOn);
  }
}
