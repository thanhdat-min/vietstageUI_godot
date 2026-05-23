3. Register content of Capstone Project 
(*) 3.1. Capstone Project name: 
English: VietStage - Virtual Artist for Vietnamese Traditional Instrument Education with Game-Based Learning
Vietnamese: VietStage - Nghệ Sĩ Ảo Dạy Nhạc Cụ Dân Tộc Với Học Tập Dựa Trên Trò Chơi
a. Context:
Vietnamese traditional music encompasses a diverse range of instruments such as đàn tranh (16-string zither), đàn bầu (monochord), sáo trúc (bamboo flute), and trống (drum). These instruments require specialized training in fingering techniques, tonal control, and rhythmic patterns unique to Vietnamese musical traditions. However, qualified traditional music instructors are concentrated in major conservatories in Hanoi and Ho Chi Minh City, leaving students in provincial areas with limited access to quality instruction.
Current online music education platforms focus predominantly on Western instruments (piano, guitar) and lack culturally appropriate content for Vietnamese folk instruments. The absence of interactive, visually engaging tools that demonstrate proper technique—such as finger placement on đàn tranh strings or breath control for sáo trúc—creates a significant barrier for self-learners.
Recent advances in 2.5D isometric game engines (Godot) and native audio processing via GDExtension (C++) enable the creation of immersive virtual learning environments where an animated virtual artist can demonstrate techniques in real-time while the system listens to and evaluates the learner’s practice through microphone input. This game-based approach transforms repetitive practice into an engaging, achievement-driven experience that preserves and promotes Vietnamese cultural heritage.
Functional requirement :
Learner Application (Godot Desktop/Mobile)
● Register/login with learner profile; select instrument of interest and current skill level
● Explore 2.5D isometric virtual music room with interactive instrument stations
● Watch virtual artist demonstrate techniques with synchronized animation and audio playback
● Enter practice mode: system captures microphone input and provides real-time visual feedback (pitch indicator, rhythm bar, accuracy meter)
● Complete structured lessons organized by instrument → technique → difficulty tier (Beginner / Intermediate / Advanced)
● Play mini-games: rhythm matching challenges, note recognition quizzes, melody completion exercises
● Earn stars (1-3) per lesson based on accuracy; unlock new lessons and cosmetic rewards for virtual room
● View personal progress dashboard: accuracy trends, practice time, completed lessons, achievement badges
● Access reference audio library with slow-motion playback and waveform visualization
● Daily practice challenges with streak rewards and leaderboard ranking
AI Audio Analysis Features (GDExtension C++)
● Real-time pitch detection using autocorrelation and YIN algorithm optimized in C++ for low-latency response (<100ms)
● Rhythm accuracy evaluation comparing onset timing against reference beat map
● Tonal quality assessment for string instruments using spectral centroid and harmonic ratio analysis
● Breath pattern analysis for wind instruments (sáo trúc) measuring sustain and attack consistency
● Performance scoring engine aggregating pitch, rhythm, dynamics, and technique metrics into composite score
● Adaptive difficulty adjustment based on rolling accuracy of last 10 practice attempts
● Audio noise gate and filtering to isolate instrument signal from background noise
Instructor Dashboard (Web)
● Upload lesson content: reference audio recordings, sheet notation images, technique descriptions
● Configure lesson structure: define exercises, set scoring thresholds, arrange curriculum order
● Monitor learner progress: aggregate statistics, individual scorecards, practice frequency reports
● Provide feedback via text comments on specific lesson attempts
Admin Panel (Web)
● User management: learner/instructor accounts, role assignment, access control
● Content moderation: review and approve uploaded lessons and audio materials
● System analytics: active users, popular instruments, session duration, retention metrics
● Application configuration: scoring parameters, difficulty curves, feature toggles
Non-functional requirement:
● Audio processing latency: < 100ms end-to-end for real-time feedback (GDExtension C++ optimization)
● Game frame rate: stable 60 FPS on mid-range devices (Godot 2.5D isometric rendering)
● Support 2,000 concurrent users on backend services
● Compatibility: Windows 10+, Android 9.0+, iOS 14.0+ (Godot cross-platform export)
● Offline mode: cached lessons playable without internet; sync progress when reconnected
● Audio capture: 44.1 kHz sample rate, 16-bit depth for instrument analysis fidelity
● Application size: < 500 MB including base instrument asset packs
 (*) 3.2. Main proposal content (including result and product)   
Proposed Solutions:
● Build a 2.5D isometric virtual classroom in Godot Engine featuring an animated virtual artist character who demonstrates instrument techniques
● Implement real-time audio recognition via GDExtension (C++) module analyzing pitch, rhythm, and tonal accuracy of learner’s practice
● Design game-based lesson structure with progressive levels, scoring, and achievement mechanics to maintain engagement
● Develop interactive instrument models (dàn tranh, dàn bầu, sáo trúc, trống) with visual feedback on finger/hand positioning
● Provide AI-powered performance evaluation comparing learner audio against reference recordings using spectral analysis
● Create a content management system for instructors to upload lessons, reference audio, and curriculum materials
Applied Theory:
Students apply iterative agile development with UML 2.0 system modeling. Documentation includes: User Requirements Specification, Software Requirements Specification, System Architecture Design, Database Schema, Audio Processing Pipeline Design, Testing Strategy & Results, User Manual, and deployable packages.
Core Game Engine & Audio Processing:
● Game Engine: Godot 4.x with 2.5D isometric tile-based rendering
● Native Audio Module: GDExtension with C++ for real-time DSP (pitch detection, onset detection, spectral analysis)
● Audio Libraries (C++): FFTW3 for FFT computation, Aubio for pitch/onset detection, PortAudio for cross-platform audio I/O
● Scripting: GDScript for game logic, UI, and animation control
● Asset Pipeline: Aseprite / Blender for 2.5D isometric character and instrument sprites
Server-side Technologies:
● Backend: Spring Boot (Java) / Python FastAPI
● Database: PostgreSQL (user data, progress, lesson metadata) + Redis (leaderboard cache, sessions)
● Cloud Storage: AWS S3 / GCP Cloud Storage for audio files and lesson assets
● API: RESTful endpoints for authentication, progress sync, content management
Client-side Technologies (Web Dashboard):
● Web Framework: ReactJS with Tailwind CSS for Instructor Dashboard and Admin Panel
● Visualization: Chart.js / Recharts for learner analytics and progress charts
Products (Expected Deliverables):
● Learner Game Application (Desktop + Mobile): Godot 2.5D isometric game with embedded C++ audio analysis engine
● Instructor Web Dashboard: Lesson management, learner monitoring, content upload interface
● Admin Web Panel: User management, system analytics, configuration
● Backend API Service: RESTful server handling authentication, data persistence, content delivery
● GDExtension Audio Module: Standalone C++ library for real-time instrument audio recognition
● Technical Documentation: Architecture diagrams, API specifications, audio pipeline documentation, user manuals, deployment guides
Proposed Tasks:
● Package 1 (Week 1-2): Project setup – Godot project structure, GDExtension C++ build pipeline, backend scaffolding, database design, authentication system
● Package 2 (Week 3-5): Core game world – 2.5D isometric virtual classroom, virtual artist character animation, instrument interaction system, lesson navigation UI
● Package 3 (Week 6-8): Audio engine – GDExtension C++ audio capture, pitch detection (YIN/autocorrelation), onset detection, spectral analysis, scoring algorithm, real-time visual feedback integration
● Package 4 (Week 9-10): Game-based learning – Mini-game templates (rhythm match, note quiz, melody completion), achievement system, adaptive difficulty, daily challenges, leaderboard
● Package 5 (Week 11-12): Web platforms – Instructor dashboard (lesson upload, learner analytics), Admin panel (user management, system config), API integration
● Package 6 (Week 13-14): Testing & deployment – Unit/integration/E2E testing, audio module performance profiling, cross-platform build verification, beta testing, documentation, production deployment
#   v i e t s t a g e U I _ g o d o t  
 