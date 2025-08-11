desc "Fill the database tables with some sample data"
task({ sample_data: :environment }) do
  puts "Sample data task running"

  Board.delete_all
  Listing.delete_all

  if Rails.env.production?
    ActiveRecord::Base.connection.tables.each do |t|
      begin
        ActiveRecord::Base.connection.execute("ALTER SEQUENCE #{t}_id_seq RESTART WITH 1")
      rescue ActiveRecord::StatementInvalid
        # Skip tables that don't have an id sequence
      end
    end
  end

  # Campus building/dorm names
  campus_locations = [
    "Harper Center",
    "Reynolds Hall",
    "Bartlett Dining Commons",
    "Max Palevsky Residential Commons",
    "Stuart Hall",
    "Cobb Hall",
    "Regenstein Library",
    "Ratner Athletics Center",
    "University Bookstore",
    "Ida Noyes Hall"
  ]

  # Sample post data for different types of campus postings
  post_templates = [
    # Roommate/Housing
    {
      titles: [
        "Looking for roommate - Spring Quarter",
        "Sublet available - Summer 2024",
        "Room available in 3BR apartment",
        "Seeking quiet roommate for double",
        "Off-campus housing near campus"
      ],
      bodies: [
        "Clean, quiet grad student looking for roommate to share 2BR apartment. $800/month + utilities. Walking distance to campus. No pets, non-smoker preferred.",
        "Subletting my room June-August. Furnished, includes utilities and WiFi. Great location on 55th Street. $750/month.",
        "Female roommate needed for spring quarter. Shared kitchen and bathroom. Laundry in building. $650/month.",
        "Looking for someone to take over my lease starting next month. Studio apartment, all utilities included. Contact me ASAP!",
        "Room available in house with 3 other students. Large kitchen, backyard, close to shuttle stop. $700/month plus share of utilities."
      ]
    },
    # Tutoring/Academic
    {
      titles: [
        "Math 151 Tutoring Available",
        "MCAT Prep Study Group Forming",
        "Writing Center Peer Tutor Hours",
        "Free Statistics Help Sessions",
        "Language Exchange: Spanish/English"
      ],
      bodies: [
        "PhD student offering calculus tutoring. $40/hour, group rates available. Helped 20+ students improve grades. Email with availability.",
        "Starting MCAT study group for June test date. Meeting twice weekly in Reg Library. All sections covered. Serious inquiries only.",
        "Peer writing tutor available MWF 2-4pm in Harper Café. Drop in for help with essays, research papers, and citations.",
        "Stats TA holding extra office hours before midterm. Room 107 in Stuart. Bring practice problems!",
        "Native Spanish speaker seeking English conversation practice. Will exchange for Spanish lessons. Meet weekly over coffee."
      ]
    },
    # Items for Sale
    {
      titles: [
        "Textbooks for Sale - Econ Major",
        "Moving Sale - Furniture Must Go!",
        "Bike for Sale - Great Condition",
        "Winter Coat - North Face L",
        "TI-89 Calculator - Like New"
      ],
      bodies: [
        "Selling all my econ textbooks. Mankiw Macro ($50), Varian Micro ($40), Econometrics ($60). Some highlighting but good condition.",
        "Graduating senior selling: desk ($30), bookshelf ($25), chair ($20), mini fridge ($80). Must pick up by Friday!",
        "Trek hybrid bike, barely used. New tires, includes lock and lights. $300 OBO. Perfect for campus commuting.",
        "Selling warm winter coat, only worn one season. Black North Face parka, size L. Paid $400, asking $200.",
        "Graphing calculator required for engineering classes. Works perfectly, includes manual. $80 (retail $150)."
      ]
    },
    # Events/Activities
    {
      titles: [
        "Jazz Ensemble Concert Tonight",
        "Intramural Basketball Team Needs Players",
        "Film Screening: Student Documentary",
        "Yoga Class - Beginners Welcome",
        "Board Game Night at Reynolds"
      ],
      bodies: [
        "UC Jazz Ensemble performing at 8pm in Mandel Hall. Free admission with student ID. Reception to follow.",
        "Co-ed basketball team looking for 2 more players. Games Sunday evenings. All skill levels welcome, just be ready to have fun!",
        "Screening my senior thesis documentary about campus sustainability. Thursday 7pm in Cobb 307. Q&A after.",
        "Free yoga sessions every Tuesday 6pm at Ratner. Mats provided. Great stress relief during finals!",
        "Weekly board game meetup, Fridays 8pm in Reynolds lounge. Bring snacks to share! New players always welcome."
      ]
    },
    # Jobs/Opportunities
    {
      titles: [
        "Research Assistant Needed",
        "Barista Position - Campus Café",
        "Paid Psychology Study Participants",
        "Dog Walker Wanted - Flexible Hours",
        "Summer Internship Opportunity"
      ],
      bodies: [
        "Economics professor seeking RA for data analysis project. 10 hrs/week, $15/hour. Experience with Stata preferred.",
        "Harper Café hiring part-time barista. Morning shifts available. Training provided. Apply in person with resume.",
        "Psych department recruiting for memory study. 2-hour session, $30 compensation. Must be 18-25 years old.",
        "Need reliable dog walker for my two labs. 3x per week, afternoons. $20/walk. Must love dogs!",
        "Local nonprofit seeking summer marketing intern. Great experience for business/communications majors. Stipend provided."
      ]
    },
    # Lost & Found
    {
      titles: [
        "Lost: Blue North Face Backpack",
        "Found: Set of Keys near Quad",
        "Missing Cat - Please Help!",
        "Found: iPhone in Library",
        "Lost: Gold Necklace - Sentimental Value"
      ],
      bodies: [
        "Left my backpack in Swift Hall yesterday. Contains laptop and notebooks. If found, please email - reward offered!",
        "Found keys on keychain with Cubs logo near main quad. Turn in to campus security or email me to claim.",
        "Orange tabby cat missing since Tuesday. Answers to 'Schrodinger'. Indoor cat, very friendly. Last seen near 57th Street.",
        "Found iPhone 12 in Reg A-level. Currently at circulation desk. Describe lock screen to claim.",
        "Lost gold chain necklace, possibly in Bartlett or gym. Gift from grandmother. Reward if found!"
      ]
    }
  ]

  # Track used titles per board to avoid duplicates
  used_titles_per_board = {}

  campus_locations.sample(5).each do |location|
    board = Board.new
    board.name = location
    board.save

    # Initialize tracking for this board
    used_titles_per_board[board.id] = Set.new

    # Create a shuffled list of all available posts
    available_posts = []
    post_templates.each do |template|
      template[:titles].each_with_index do |title, index|
        available_posts << { template: template, title_index: index }
      end
    end
    available_posts.shuffle!

    # Select a random number of posts, ensuring no duplicates
    num_posts = rand(3..10)
    selected_posts = available_posts.first(num_posts)

    selected_posts.each do |post_data|
      template = post_data[:template]
      title_index = post_data[:title_index]

      listing = Listing.new
      listing.board_id = board.id
      listing.title = template[:titles][title_index]
      listing.body = template[:bodies][title_index]

      # More realistic date ranges for campus postings
      listing.created_at = Faker::Date.backward(days: 30)

      # Different expiration patterns based on post type
      if template[:titles][title_index].include?("Lost") || template[:titles][title_index].include?("Found")
        listing.expires_on = Faker::Date.between(from: listing.created_at + 7.days, to: listing.created_at + 14.days)
      elsif template[:titles][title_index].include?("Sale") || template[:titles][title_index].include?("Moving")
        listing.expires_on = Faker::Date.between(from: listing.created_at + 3.days, to: listing.created_at + 10.days)
      else
        listing.expires_on = Faker::Date.between(from: listing.created_at + 14.days, to: listing.created_at + 45.days)
      end

      listing.save
    end
  end

  puts "There are now #{Board.count} rows in the boards table."
  puts "There are now #{Listing.count} rows in the listings table."
end
