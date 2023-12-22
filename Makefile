

.PHONY: depends

depends:
	sudo apt-get install -y asciidoctor
	sudo gem install asciidoctor-rouge
	# sudo gem install asciidoctor-question
	# sudo gem install asciidoctor-mathematical
	sudo gem install asciidoctor-katex
	sudo gem install asciidoctor-interdoc-reftext
	sudo gem install asciidoctor-diagram
	# sudo gem install asciidoctor-bibtex
	sudo gem install asciidoctor-html5s


