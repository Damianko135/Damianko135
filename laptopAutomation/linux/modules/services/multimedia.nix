{ config, pkgs, ... }:

{
  # Multimedia packages
  environment.systemPackages = with pkgs; [
    # Video players
    vlc
    mpv
    totem
    
    # Audio players
    rhythmbox
    clementine
    audacious
    
    # Music streaming
    spotify
    
    # Video editors
    kdenlive
    openshot-qt
    shotcut
    
    # Audio editors
    audacity
    
    # Image viewers
    eog
    gwenview
    feh
    
    # Image editors
    gimp
    krita
    inkscape
    
    # Photo management
    digikam
    shotwell
    
    # 3D modeling
    blender
    
    # Screen recording
    obs-studio
    simplescreenrecorder
    
    # Video converters
    ffmpeg
    handbrake
    
    # Audio converters
    soundconverter
    
    # Codecs
    gstreamer
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    
    # Image formats
    imagemagick
    
    # PDF tools
    poppler_utils
    
    # E-book readers
    calibre
    foliate
    
    # Comic book readers
    mcomix
    
    # Media servers
    plex
    jellyfin
    
    # Streaming tools
    youtube-dl
    yt-dlp
    
    # Webcam tools
    cheese
    guvcview
    
    # Audio production
    ardour
    lmms
    
    # DJ software
    mixxx
    
    # Video streaming
    streamlink
    
    # Subtitle editors
    subtitleedit
    
    # Media info
    mediainfo
    exiftool
    
    # CD/DVD tools
    brasero
    k3b
    
    # Audio visualization
    cava
    
    # Video thumbnails
    ffmpegthumbnailer
    
    # Screen capture
    maim
    scrot
    
    # Color picker
    gcolor3
    
    # Font viewer
    font-manager
    
    # Icon viewer
    icon-library
    
    # Archive tools for media
    p7zip
    unrar
    
    # Network media
    samba
    
    # Torrent client
    transmission
    qbittorrent
    
    # IRC client
    hexchat
    
    # Video conferencing
    zoom-us
    teams
    discord
    
    # Voice chat
    mumble
    
    # Podcast client
    gpodder
    
    # Radio
    shortwave
    
    # Music theory
    musescore
    
    # Animation
    synfig
    
    # Vector graphics
    dia
    
    # CAD
    freecad
    
    # Game engines
    godot
    
    # Game development
    love
    
    # Emulation
    retroarch
    
    # Gaming
    steam
    lutris
    
    # Game streaming
    moonlight-qt
    
    # Productivity
    libreoffice
    
    # Note taking
    obsidian
    joplin-desktop
    
    # Mind mapping
    xmind
    
    # Presentation
    impressive
    
    # Diagram tools
    drawio
    
    # Password manager
    bitwarden
    
    # VPN clients
    openvpn
    networkmanager-openvpn
    
    # Remote desktop
    remmina
    teamviewer
    
    # File sharing
    nextcloud-client
    
    # Cloud storage
    dropbox
    
    # Messaging
    telegram-desktop
    signal-desktop
    
    # Email
    thunderbird
    
    # Web browsers
    firefox
    chromium
    
    # Development browsers
    google-chrome
    
    # Security
    keepassxc
    
    # System monitoring
    htop
    btop
    
    # Network monitoring
    wireshark
    
    # Backup
    timeshift
    
    # Virtualization
    virtualbox
    
    # Wine for Windows apps
    wine
    winetricks
    
    # Android tools
    android-studio
    
    # iOS tools
    libimobiledevice
    
    # Cross-platform development
    flutter
    
    # Machine learning
    python3Packages.tensorflow
    python3Packages.pytorch
    
    # Data science
    python3Packages.jupyter
    python3Packages.matplotlib
    python3Packages.numpy
    python3Packages.pandas
    
    # Statistics
    r
    rstudio
    
    # Scientific computing
    octave
    
    # Chemistry
    avogadro
    
    # Physics
    kstars
    
    # Geography
    qgis
    
    # Astronomy
    stellarium
    
    # Weather
    gnome-weather
    
    # Calculator
    gnome-calculator
    qalculate-gtk
    
    # Unit converter
    units
    
    # Color management
    argyllcms
    
    # Printing
    cups
    
    # Scanning
    simple-scan
    
    # Fax
    efax-gtk
    
    # Archiving
    ark
    
    # Disk usage
    baobab
    
    # Partition manager
    gparted
    
    # System cleaner
    bleachbit
    
    # Performance tuning
    cpufrequtils
    
    # Power management
    powertop
    
    # Hardware info
    hardinfo
    
    # Benchmarking
    phoronix-test-suite
    
    # Stress testing
    stress-ng
    
    # Memory testing
    memtest86plus
    
    # Network testing
    iperf3
    
    # Disk testing
    hdparm
    
    # GPU testing
    glmark2
    
    # Temperature monitoring
    psensor
    
    # Fan control
    fancontrol
    
    # Overclocking
    msr-tools
    
    # Firmware updates
    fwupd
    
    # Driver management
    nvidia-settings
    
    # Display management
    arandr
    
    # Color calibration
    displaycal
    
    # Accessibility
    orca
    
    # Text to speech
    espeak
    
    # Speech recognition
    julius
    
    # Magnifier
    magnus
    
    # Virtual keyboard
    onboard
    
    # Mouse control
    easystroke
    
    # Eye tracking
    tobii-stream-engine
    
    # Gesture recognition
    libinput-gestures
    
    # Automation
    xdotool
    
    # Clipboard manager
    copyq
    
    # Session management
    tmux
    
    # Window management
    wmctrl
    
    # Desktop widgets
    conky
    
    # Wallpaper management
    variety
    
    # Icon themes
    papirus-icon-theme
    
    # Cursor themes
    capitaine-cursors
    
    # GTK themes
    arc-theme
    
    # Fonts
    noto-fonts
    noto-fonts-emoji
    
    # Terminal fonts
    fira-code
    
    # Symbol fonts
    font-awesome
    
    # Programming fonts
    jetbrains-mono
    
    # Design fonts
    inter
    
    # Handwriting fonts
    kalam
    
    # Display fonts
    raleway
    
    # Serif fonts
    source-serif-pro
    
    # Sans-serif fonts
    source-sans-pro
    
    # Monospace fonts
    source-code-pro
    
    # Mathematics fonts
    tex-gyre
    
    # Unicode fonts
    unifont
    
    # Emoji fonts
    noto-fonts-color-emoji
    
    # CJK fonts
    noto-fonts-cjk
    
    # Arabic fonts
    amiri
    
    # Hebrew fonts
    culmus
    
    # Devanagari fonts
    lohit-fonts
    
    # Thai fonts
    thai-fonts
    
    # Korean fonts
    nanum
    
    # Japanese fonts
    ipafont
    
    # Chinese fonts
    source-han-sans
    
    # Indic fonts
    lohit-fonts
    
    # African fonts
    ubuntu-font-family
    
    # Gaming fonts
    creep
    
    # Pixel fonts
    pixelsize
    
    # Retro fonts
    mplus-outline-fonts
    
    # Coding fonts
    cascadia-code
    
    # System fonts
    liberation_ttf
    
    # Windows fonts
    corefonts
    
    # Adobe fonts
    source-serif-4
    
    # Google fonts
    google-fonts
    
    # Font tools
    fontforge
    
    # Font preview
    font-manager
    
    # Character map
    gucharmap
    
    # Typography
    scribus
    
    # Layout
    pagemaker
    
    # Publishing
    lyx
    
    # Typesetting
    texlive.combined.scheme-full
    
    # Bibliography
    jabref
    
    # Reference management
    zotero
    
    # Document conversion
    pandoc
    
    # Markup languages
    markdown
    
    # Wiki software
    dokuwiki
    
    # Content management
    drupal
    
    # E-commerce
    magento
    
    # Social media
    hootsuite
    
    # Marketing
    mailchimp
    
    # Analytics
    google-analytics
    
    # SEO
    screaming-frog-seo-spider
    
    # Web development
    nodejs
    
    # Frontend frameworks
    angular-cli
    
    # Backend frameworks
    django
    
    # Database management
    mysql-workbench
    
    # API development
    postman
    
    # Version control
    git
    
    # Code editors
    vscode
    
    # IDEs
    jetbrains.idea-ultimate
    
    # Collaboration
    slack
    
    # Project management
    trello
    
    # Time tracking
    toggl
    
    # Invoicing
    gnucash
    
    # Accounting
    homebank
    
    # Budgeting
    budgie-desktop
    
    # Investment tracking
    portfolio
    
    # Cryptocurrency
    electrum
    
    # Trading
    metatrader
    
    # Banking
    banking-software
    
    # Insurance
    insurance-software
    
    # Legal
    legal-software
    
    # Medical
    medical-software
    
    # Education
    educational-software
    
    # Language learning
    anki
    
    # Translation
    translate-shell
    
    # Dictionary
    goldendict
    
    # Thesaurus
    artha
    
    # Grammar checker
    languagetool
    
    # Spell checker
    hunspell
    
    # Text editor
    sublime-text
    
    # Code formatter
    prettier
    
    # Linter
    eslint
    
    # Debugger
    gdb
    
    # Profiler
    valgrind
    
    # Compiler
    gcc
    
    # Interpreter
    python3
    
    # Virtual machine
    qemu
    
    # Container
    docker
    
    # Orchestration
    kubernetes
    
    # Infrastructure
    terraform
    
    # Configuration management
    ansible
    
    # Monitoring
    prometheus
    
    # Logging
    logstash
    
    # Visualization
    grafana
    
    # Alerting
    alertmanager
    
    # Service mesh
    istio
    
    # API gateway
    kong
    
    # Load balancer
    nginx
    
    # Reverse proxy
    traefik
    
    # CDN
    cloudflare
    
    # DNS
    bind
    
    # DHCP
    dhcpd
    
    # VPN
    openvpn
    
    # Firewall
    iptables
    
    # IDS/IPS
    suricata
    
    # SIEM
    elastic-stack
    
    # Vulnerability scanner
    nmap
    
    # Penetration testing
    metasploit
    
    # Forensics
    autopsy
    
    # Malware analysis
    cuckoo
    
    # Threat intelligence
    misp
    
    # Incident response
    the-hive
    
    # Compliance
    nessus
    
    # Risk management
    risk-management-software
    
    # Governance
    governance-software
    
    # Audit
    audit-software
    
    # Business continuity
    business-continuity-software
    
    # Disaster recovery
    disaster-recovery-software
    
    # Backup
    bacula
    
    # Archive
    archivematica
    
    # Digital preservation
    digital-preservation-software
    
    # Records management
    records-management-software
    
    # Document management
    document-management-software
    
    # Content management
    content-management-software
    
    # Knowledge management
    knowledge-management-software
    
    # Collaboration
    collaboration-software
    
    # Communication
    communication-software
    
    # Social networking
    social-networking-software
    
    # Community management
    community-management-software
    
    # Customer relationship management
    crm-software
    
    # Enterprise resource planning
    erp-software
    
    # Human resources
    hr-software
    
    # Payroll
    payroll-software
    
    # Time and attendance
    time-attendance-software
    
    # Performance management
    performance-management-software
    
    # Learning management
    learning-management-software
    
    # Talent management
    talent-management-software
    
    # Recruitment
    recruitment-software
    
    # Onboarding
    onboarding-software
    
    # Training
    training-software
    
    # Certification
    certification-software
    
    # Compliance training
    compliance-training-software
    
    # Safety training
    safety-training-software
    
    # Security awareness
    security-awareness-software
    
    # Privacy training
    privacy-training-software
    
    # Data protection
    data-protection-software
    
    # GDPR compliance
    gdpr-compliance-software
    
    # Information security
    information-security-software
    
    # Cybersecurity
    cybersecurity-software
    
    # Network security
    network-security-software
    
    # Endpoint security
    endpoint-security-software
    
    # Mobile security
    mobile-security-software
    
    # Cloud security
    cloud-security-software
    
    # Application security
    application-security-software
    
    # Database security
    database-security-software
    
    # Email security
    email-security-software
    
    # Web security
    web-security-software
    
    # Identity and access management
    identity-access-management-software
    
    # Privileged access management
    privileged-access-management-software
    
    # Single sign-on
    single-sign-on-software
    
    # Multi-factor authentication
    multi-factor-authentication-software
    
    # Biometric authentication
    biometric-authentication-software
    
    # Certificate management
    certificate-management-software
    
    # Key management
    key-management-software
    
    # Encryption
    encryption-software
    
    # Digital signatures
    digital-signatures-software
    
    # Blockchain
    blockchain-software
    
    # Cryptocurrency
    cryptocurrency-software
    
    # Smart contracts
    smart-contracts-software
    
    # Decentralized applications
    decentralized-applications-software
    
    # Distributed systems
    distributed-systems-software
    
    # Microservices
    microservices-software
    
    # Serverless computing
    serverless-computing-software
    
    # Edge computing
    edge-computing-software
    
    # Internet of Things
    iot-software
    
    # Artificial intelligence
    ai-software
    
    # Machine learning
    machine-learning-software
    
    # Deep learning
    deep-learning-software
    
    # Natural language processing
    nlp-software
    
    # Computer vision
    computer-vision-software
    
    # Robotics
    robotics-software
    
    # Automation
    automation-software
    
    # Process automation
    process-automation-software
    
    # Workflow automation
    workflow-automation-software
    
    # Business process management
    bpm-software
    
    # Robotic process automation
    rpa-software
    
    # Intelligent automation
    intelligent-automation-software
    
    # Cognitive automation
    cognitive-automation-software
    
    # Conversational AI
    conversational-ai-software
    
    # Chatbots
    chatbot-software
    
    # Virtual assistants
    virtual-assistant-software
    
    # Voice recognition
    voice-recognition-software
    
    # Speech synthesis
    speech-synthesis-software
    
    # Language translation
    language-translation-software
    
    # Localization
    localization-software
    
    # Globalization
    globalization-software
    
    # Cultural adaptation
    cultural-adaptation-software
    
    # Accessibility
    accessibility-software
    
    # Assistive technology
    assistive-technology-software
    
    # Disability support
    disability-support-software
    
    # Inclusive design
    inclusive-design-software
    
    # Universal design
    universal-design-software
    
    # User experience
    user-experience-software
    
    # User interface
    user-interface-software
    
    # Interaction design
    interaction-design-software
    
    # Visual design
    visual-design-software
    
    # Graphic design
    graphic-design-software
    
    # Web design
    web-design-software
    
    # Mobile design
    mobile-design-software
    
    # Responsive design
    responsive-design-software
    
    # Prototyping
    prototyping-software
    
    # Wireframing
    wireframing-software
    
    # Mockups
    mockup-software
    
    # Style guides
    style-guide-software
    
    # Design systems
    design-system-software
    
    # Brand management
    brand-management-software
    
    # Asset management
    asset-management-software
    
    # Digital asset management
    digital-asset-management-software
    
    # Media asset management
    media-asset-management-software
    
    # Creative asset management
    creative-asset-management-software
    
    # Brand asset management
    brand-asset-management-software
    
    # Marketing asset management
    marketing-asset-management-software
    
    # Content asset management
    content-asset-management-software
    
    # Video asset management
    video-asset-management-software
    
    # Audio asset management
    audio-asset-management-software
    
    # Image asset management
    image-asset-management-software
    
    # Document asset management
    document-asset-management-software
    
    # File asset management
    file-asset-management-software
    
    # Data asset management
    data-asset-management-software
    
    # Information asset management
    information-asset-management-software
    
    # Knowledge asset management
    knowledge-asset-management-software
    
    # Intellectual property management
    intellectual-property-management-software
    
    # Patent management
    patent-management-software
    
    # Trademark management
    trademark-management-software
    
    # Copyright management
    copyright-management-software
    
    # Licensing management
    licensing-management-software
    
    # Royalty management
    royalty-management-software
    
    # Contract management
    contract-management-software
    
    # Legal document management
    legal-document-management-software
    
    # Compliance management
    compliance-management-software
    
    # Risk management
    risk-management-software
    
    # Governance management
    governance-management-software
    
    # Audit management
    audit-management-software
    
    # Quality management
    quality-management-software
    
    # Process management
    process-management-software
    
    # Performance management
    performance-management-software
    
    # Productivity management
    productivity-management-software
    
    # Efficiency management
    efficiency-management-software
    
    # Optimization management
    optimization-management-software
    
    # Innovation management
    innovation-management-software
    
    # Strategy management
    strategy-management-software
    
    # Planning management
    planning-management-software
    
    # Execution management
    execution-management-software
    
    # Monitoring management
    monitoring-management-software
    
    # Evaluation management
    evaluation-management-software
    
    # Improvement management
    improvement-management-software
    
    # Transformation management
    transformation-management-software
    
    # Change management
    change-management-software
    
    # Project management
    project-management-software
    
    # Program management
    program-management-software
    
    # Portfolio management
    portfolio-management-software
    
    # Resource management
    resource-management-software
    
    # Capacity management
    capacity-management-software
    
    # Demand management
    demand-management-software
    
    # Supply management
    supply-management-software
    
    # Vendor management
    vendor-management-software
    
    # Supplier management
    supplier-management-software
    
    # Procurement management
    procurement-management-software
    
    # Sourcing management
    sourcing-management-software
    
    # Purchasing management
    purchasing-management-software
    
    # Inventory management
    inventory-management-software
    
    # Warehouse management
    warehouse-management-software
    
    # Distribution management
    distribution-management-software
    
    # Logistics management
    logistics-management-software
    
    # Transportation management
    transportation-management-software
    
    # Fleet management
    fleet-management-software
    
    # Asset tracking
    asset-tracking-software
    
    # Location tracking
    location-tracking-software
    
    # GPS tracking
    gps-tracking-software
    
    # Route optimization
    route-optimization-software
    
    # Delivery management
    delivery-management-software
    
    # Fulfillment management
    fulfillment-management-software
    
    # Order management
    order-management-software
    
    # E-commerce management
    e-commerce-management-software
    
    # Retail management
    retail-management-software
    
    # Point of sale
    point-of-sale-software
    
    # Payment processing
    payment-processing-software
    
    # Financial management
    financial-management-software
    
    # Accounting management
    accounting-management-software
    
    # Bookkeeping management
    bookkeeping-management-software
    
    # Tax management
    tax-management-software
    
    # Audit management
    audit-management-software
    
    # Budgeting management
    budgeting-management-software
    
    # Forecasting management
    forecasting-management-software
    
    # Planning management
    planning-management-software
    
    # Analysis management
    analysis-management-software
    
    # Reporting management
    reporting-management-software
    
    # Dashboard management
    dashboard-management-software
    
    # Visualization management
    visualization-management-software
    
    # Business intelligence
    business-intelligence-software
    
    # Data analytics
    data-analytics-software
    
    # Big data
    big-data-software
    
    # Data science
    data-science-software
    
    # Data engineering
    data-engineering-software
    
    # Data integration
    data-integration-software
    
    # Data migration
    data-migration-software
    
    # Data synchronization
    data-synchronization-software
    
    # Data replication
    data-replication-software
    
    # Data backup
    data-backup-software
    
    # Data recovery
    data-recovery-software
    
    # Data archiving
    data-archiving-software
    
    # Data retention
    data-retention-software
    
    # Data governance
    data-governance-software
    
    # Data quality
    data-quality-software
    
    # Data validation
    data-validation-software
    
    # Data cleansing
    data-cleansing-software
    
    # Data transformation
    data-transformation-software
    
    # Data modeling
    data-modeling-software
    
    # Data visualization
    data-visualization-software
    
    # Data storytelling
    data-storytelling-software
    
    # Data communication
    data-communication-software
    
    # Data sharing
    data-sharing-software
    
    # Data collaboration
    data-collaboration-software
    
    # Data marketplace
    data-marketplace-software
    
    # Data monetization
    data-monetization-software
    
    # Data privacy
    data-privacy-software
    
    # Data security
    data-security-software
    
    # Data protection
    data-protection-software
    
    # Data classification
    data-classification-software
    
    # Data discovery
    data-discovery-software
    
    # Data catalog
    data-catalog-software
    
    # Data lineage
    data-lineage-software
    
    # Data provenance
    data-provenance-software
    
    # Data versioning
    data-versioning-software
    
    # Data lifecycle management
    data-lifecycle-management-software
    
    # Master data management
    master-data-management-software
    
    # Reference data management
    reference-data-management-software
    
    # Metadata management
    metadata-management-software
    
    # Data dictionary
    data-dictionary-software
    
    # Data glossary
    data-glossary-software
    
    # Data standards
    data-standards-software
    
    # Data architecture
    data-architecture-software
    
    # Data infrastructure
    data-infrastructure-software
    
    # Data platform
    data-platform-software
    
    # Data warehouse
    data-warehouse-software
    
    # Data lake
    data-lake-software
    
    # Data mart
    data-mart-software
    
    # Data hub
    data-hub-software
    
    # Data fabric
    data-fabric-software
    
    # Data mesh
    data-mesh-software
    
    # Data virtualization
    data-virtualization-software
    
    # Data federation
    data-federation-software
    
    # Data streaming
    data-streaming-software
    
    # Real-time data
    real-time-data-software
    
    # Event streaming
    event-streaming-software
    
    # Message queuing
    message-queuing-software
    
    # Pub/sub messaging
    pub-sub-messaging-software
    
    # Event-driven architecture
    event-driven-architecture-software
    
    # Service-oriented architecture
    service-oriented-architecture-software
    
    # API management
    api-management-software
    
    # API gateway
    api-gateway-software
    
    # API security
    api-security-software
    
    # API testing
    api-testing-software
    
    # API documentation
    api-documentation-software
    
    # API monitoring
    api-monitoring-software
    
    # API analytics
    api-analytics-software
    
    # API governance
    api-governance-software
    
    # API lifecycle management
    api-lifecycle-management-software
    
    # Integration platform
    integration-platform-software
    
    # iPaaS
    ipaas-software
    
    # ETL
    etl-software
    
    # ELT
    elt-software
    
    # Data pipeline
    data-pipeline-software
    
    # Workflow orchestration
    workflow-orchestration-software
    
    # Job scheduling
    job-scheduling-software
    
    # Task automation
    task-automation-software
    
    # Batch processing
    batch-processing-software
    
    # Stream processing
    stream-processing-software
    
    # Complex event processing
    complex-event-processing-software
    
    # Event sourcing
    event-sourcing-software
    
    # CQRS
    cqrs-software
    
    # Domain-driven design
    domain-driven-design-software
    
    # Clean architecture
    clean-architecture-software
    
    # Hexagonal architecture
    hexagonal-architecture-software
    
    # Onion architecture
    onion-architecture-software
    
    # Layered architecture
    layered-architecture-software
    
    # Component-based architecture
    component-based-architecture-software
    
    # Plugin architecture
    plugin-architecture-software
    
    # Microkernel architecture
    microkernel-architecture-software
    
    # Space-based architecture
    space-based-architecture-software
    
    # Event-driven architecture
    event-driven-architecture-software
    
    # Reactive architecture
    reactive-architecture-software
    
    # Functional architecture
    functional-architecture-software
    
    # Object-oriented architecture
    object-oriented-architecture-software
    
    # Aspect-oriented architecture
    aspect-oriented-architecture-software
    
    # Component-oriented architecture
    component-oriented-architecture-software
    
    # Service-oriented architecture
    service-oriented-architecture-software
    
    # Resource-oriented architecture
    resource-oriented-architecture-software
    
    # REST architecture
    rest-architecture-software
    
    # GraphQL architecture
    graphql-architecture-software
    
    # gRPC architecture
    grpc-architecture-software
    
    # Message-oriented architecture
    message-oriented-architecture-software
    
    # Document-oriented architecture
    document-oriented-architecture-software
    
    # Key-value architecture
    key-value-architecture-software
    
    # Column-family architecture
    column-family-architecture-software
    
    # Graph architecture
    graph-architecture-software
    
    # Multi-model architecture
    multi-model-architecture-software
    
    # Polyglot persistence
    polyglot-persistence-software
    
    # Database sharding
    database-sharding-software
    
    # Database replication
    database-replication-software
    
    # Database clustering
    database-clustering-software
    
    # Database partitioning
    database-partitioning-software
    
    # Database indexing
    database-indexing-software
    
    # Database optimization
    database-optimization-software
    
    # Database monitoring
    database-monitoring-software
    
    # Database backup
    database-backup-software
    
    # Database recovery
    database-recovery-software
    
    # Database migration
    database-migration-software
    
    # Database versioning
    database-versioning-software
    
    # Database schema management
    database-schema-management-software
    
    # Database documentation
    database-documentation-software
    
    # Database testing
    database-testing-software
    
    # Database security
    database-security-software
    
    # Database encryption
    database-encryption-software
    
    # Database access control
    database-access-control-software
    
    # Database auditing
    database-auditing-software
    
    # Database compliance
    database-compliance-software
    
    # Database governance
    database-governance-software
    
    # Database administration
    database-administration-software
    
    # Database development
    database-development-software
    
    # Database modeling
    database-modeling-software
    
    # Database design
    database-design-software
    
    # Database architecture
    database-architecture-software
    
    # Database engineering
    database-engineering-software
    
    # Database DevOps
    database-devops-software
    
    # Database as a Service
    database-as-a-service-software
    
    # Cloud database
    cloud-database-software
    
    # Multi-cloud database
    multi-cloud-database-software
    
    # Hybrid cloud database
    hybrid-cloud-database-software
    
    # Edge database
    edge-database-software
    
    # Distributed database
    distributed-database-software
    
    # Federated database
    federated-database-software
    
    # Virtual database
    virtual-database-software
    
    # In-memory database
    in-memory-database-software
    
    # Time-series database
    time-series-database-software
    
    # Spatial database
    spatial-database-software
    
    # Graph database
    graph-database-software
    
    # Document database
    document-database-software
    
    # Key-value database
    key-value-database-software
    
    # Column-family database
    column-family-database-software
    
    # Multi-model database
    multi-model-database-software
    
    # NewSQL database
    newsql-database-software
    
    # NoSQL database
    nosql-database-software
    
    # Relational database
    relational-database-software
    
    # Object database
    object-database-software
    
    # Hierarchical database
    hierarchical-database-software
    
    # Network database
    network-database-software
    
    # Flat file database
    flat-file-database-software
    
    # Embedded database
    embedded-database-software
    
    # Mobile database
    mobile-database-software
    
    # Offline database
    offline-database-software
    
    # Real-time database
    real-time-database-software
    
    # Streaming database
    streaming-database-software
    
    # Analytical database
    analytical-database-software
    
    # Operational database
    operational-database-software
    
    # Transactional database
    transactional-database-software
    
    # Data warehouse
    data-warehouse-software
    
    # Data lake
    data-lake-software
    
    # Data mart
    data-mart-software
    
    # Data hub
    data-hub-software
    
    # Data fabric
    data-fabric-software
    
    # Data mesh
    data-mesh-software
    
    # Data virtualization
    data-virtualization-software
    
    # Data federation
    data-federation-software
    
    # Data streaming
    data-streaming-software
    
    # Real-time data
    real-time-data-software
    
    # Event streaming
    event-streaming-software
    
    # Message queuing
    message-queuing-software
    
    # Pub/sub messaging
    pub-sub-messaging-software
    
    # Event-driven architecture
    event-driven-architecture-software
    
    # Service-oriented architecture
    service-oriented-architecture-software
    
    # API management
    api-management-software
    
    # API gateway
    api-gateway-software
    
    # API security
    api-security-software
    
    # API testing
    api-testing-software
    
    # API documentation
    api-documentation-software
    
    # API monitoring
    api-monitoring-software
    
    # API analytics
    api-analytics-software
    
    # API governance
    api-governance-software
    
    # API lifecycle management
    api-lifecycle-management-software
    
    # Integration platform
    integration-platform-software
    
    # iPaaS
    ipaas-software
    
    # ETL
    etl-software
    
    # ELT
    elt-software
    
    # Data pipeline
    data-pipeline-software
    
    # Workflow orchestration
    workflow-orchestration-software
    
    # Job scheduling
    job-scheduling-software
    
    # Task automation
    task-automation-software
    
    # Batch processing
    batch-processing-software
    
    # Stream processing
    stream-processing-software
    
    # Complex event processing
    complex-event-processing-software
    
    # Event sourcing
    event-sourcing-software
    
    # CQRS
    cqrs-software
    
    # Domain-driven design
    domain-driven-design-software
    
    # Clean architecture
    clean-architecture-software
    
    # Hexagonal architecture
    hexagonal-architecture-software
    
    # Onion architecture
    onion-architecture-software
    
    # Layered architecture
    layered-architecture-software
    
    # Component-based architecture
    component-based-architecture-software
    
    # Plugin architecture
    plugin-architecture-software
    
    # Microkernel architecture
    microkernel-architecture-software
    
    # Space-based architecture
    space-based-architecture-software
    
    # Event-driven architecture
    event-driven-architecture-software
    
    # Reactive architecture
    reactive-architecture-software
    
    # Functional architecture
    functional-architecture-software
    
    # Object-oriented architecture
    object-oriented-architecture-software
    
    # Aspect-oriented architecture
    aspect-oriented-architecture-software
    
    # Component-oriented architecture
    component-oriented-architecture-software
    
    # Service-oriented architecture
    service-oriented-architecture-software
    
    # Resource-oriented architecture
    resource-oriented-architecture-software
    
    # REST architecture
    rest-architecture-software
    
    # GraphQL architecture
    graphql-architecture-software
    
    # gRPC architecture
    grpc-architecture-software
    
    # Message-oriented architecture
    message-oriented-architecture-software
    
    # Document-oriented architecture
    document-oriented-architecture-software
    
    # Key-value architecture
    key-value-architecture-software
    
    # Column-family architecture
    column-family-architecture-software
    
    # Graph architecture
    graph-architecture-software
    
    # Multi-model architecture
    multi-model-architecture-software
    
    # Polyglot persistence
    polyglot-persistence-software
    
    # Database sharding
    database-sharding-software
    
    # Database replication
    database-replication-software
    
    # Database clustering
    database-clustering-software
    
    # Database partitioning
    database-partitioning-software
    
    # Database indexing
    database-indexing-software
    
    # Database optimization
    database-optimization-software
    
    # Database monitoring
    database-monitoring-software
    
    # Database backup
    database-backup-software
    
    # Database recovery
    database-recovery-software
    
    # Database migration
    database-migration-software
    
    # Database versioning
    database-versioning-software
    
    # Database schema management
    database-schema-management-software
    
    # Database documentation
    database-documentation-software
    
    # Database testing
    database-testing-software
    
    # Database security
    database-security-software
    
    # Database encryption
    database-encryption-software
    
    # Database access control
    database-access-control-software
    
    # Database auditing
    database-auditing-software
    
    # Database compliance
    database-compliance-software
    
    # Database governance
    database-governance-software
    
    # Database administration
    database-administration-software
    
    # Database development
    database-development-software
    
    # Database modeling
    database-modeling-software
    
    # Database design
    database-design-software
    
    # Database architecture
    database-architecture-software
    
    # Database engineering
    database-engineering-software
    
    # Database DevOps
    database-devops-software
    
    # Database as a Service
    database-as-a-service-software
    
    # Cloud database
    cloud-database-software
    
    # Multi-cloud database
    multi-cloud-database-software
    
    # Hybrid cloud database
    hybrid-cloud-database-software
    
    # Edge database
    edge-database-software
    
    # Distributed database
    distributed-database-software
    
    # Federated database
    federated-database-software
    
    # Virtual database
    virtual-database-software
    
    # In-memory database
    in-memory-database-software
    
    # Time-series database
    time-series-database-software
    
    # Spatial database
    spatial-database-software
    
    # Graph database
    graph-database-software
    
    # Document database
    document-database-software
    
    # Key-value database
    key-value-database-software
    
    # Column-family database
    column-family-database-software
    
    # Multi-model database
    multi-model-database-software
    
    # NewSQL database
    newsql-database-software
    
    # NoSQL database
    nosql-database-software
    
    # Relational database
    relational-database-software
    
    # Object database
    object-database-software
    
    # Hierarchical database
    hierarchical-database-software
    
    # Network database
    network-database-software
    
    # Flat file database
    flat-file-database-software
    
    # Embedded database
    embedded-database-software
    
    # Mobile database
    mobile-database-software
    
    # Offline database
    offline-database-software
    
    # Real-time database
    real-time-database-software
    
    # Streaming database
    streaming-database-software
    
    # Analytical database
    analytical-database-software
    
    # Operational database
    operational-database-software
    
    # Transactional database
    transactional-database-software
  ];

  # Audio/Video services
  services = {
    # PulseAudio (alternative to PipeWire)
    # pulseaudio = {
    #   enable = true;
    #   support32Bit = true;
    # };
    
    # PipeWire (modern audio system)
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      
      # Low-latency configuration
      config.pipewire = {
        "context.properties" = {
          "link.max-buffers" = 16;
          "log.level" = 2;
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 32;
          "default.clock.min-quantum" = 32;
          "default.clock.max-quantum" = 32;
        };
      };
    };
  };

  # Hardware acceleration
  hardware = {
    # OpenGL/Vulkan
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      
      # Additional packages
      extraPackages = with pkgs; [
        intel-media-driver
        vaapiIntel
        vaapiVdpau
        libvdpau-va-gl
        intel-compute-runtime
      ];
    };
    
    # Bluetooth audio
    bluetooth = {
      enable = true;
      hsphfpd.enable = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
        };
      };
    };
  };

  # Multimedia-related system configuration
  environment.variables = {
    # Video acceleration
    LIBVA_DRIVER_NAME = "iHD";
    
    # Audio
    PULSE_RUNTIME_PATH = "/run/user/1000/pulse";
    
    # Multimedia applications
    BROWSER = "firefox";
    PLAYER = "mpv";
    EDITOR = "vim";
  };

  # Gaming support
  programs = {
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
    
    # Game development
    gamemode.enable = true;
  };

  # Additional media codecs
  nixpkgs.config = {
    allowUnfree = true;
    
    # Enable additional codecs
    packageOverrides = pkgs: {
      gst_all_1 = pkgs.gst_all_1 // {
        gst-plugins-good = pkgs.gst_all_1.gst-plugins-good.override {
          gtkSupport = true;
        };
        gst-plugins-bad = pkgs.gst_all_1.gst-plugins-bad.override {
          enableZbar = true;
        };
      };
    };
  };
}