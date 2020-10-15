import Element from '@/components/element/';

export default {
  name: 'main-window',
  components: {
    Element,
  },
  sockets: {
    updateState(state) {
      this.$store.dispatch('UPDATE_ELEMENTS', state.Objects);
    },
    updateStats(stats) {
      this.$store.dispatch('SET_USAGES', stats.Usage.Objects);
      this.$store.dispatch('SET_PATTERNS', stats.Patterns)
      this.$refs['stats-modal'].show();
      console.log(this.$store);
    },
  },
  data() {
    return {
      code: '',
      changedElements: [],
      delay: 30,
    };
  },
  computed: {
    elements() {
      return this.$store.getters.ELEMENTS;
    },
    usages() {
      return this.$store.getters.USAGES;
    },
    usagesElements() {
      return this.usages.filter(el => el.Nature === 'register')
        .sort((a, b) => b.Value - a.Value);
    },
    usagesCommands() {
      return this.usages.filter(el => el.Nature === 'command')
        .sort((a, b) => b.Value - a.Value);
    },
    patterns() {
      return this.$store.getters.PATTERNS.map(el => ({
        Pattern: el.Pattern.split('command(').join('')
          .split(')').join('')
          .split(', \'[\', ').join('[')
          .split(', \']\'').join(']')
          .split(', \'-\', ').join('-')
          .split(', \'+\', ').join('+')
          .split('\n'),
        Count: el.Count,
      }))
        .sort((a, b) => b.Count - a.Count);
    },
  },
  methods: {
    valueChanged(ev) {
      const id = this.changedElements
        .findIndex(el => el.Name === ev.Name && el.Nature === ev.Nature);
      if (id !== -1) { this.changedElements[id] = ev; } else { this.changedElements.push(ev); }
    },
    retrieveState() {
      this.$socket.emit('retrieveState');
    },
    setState() {
      const code = this.code.split('\n')
        .map(line => line.trim()
          .split(',')
          .join('')
          .split(' ')
          .join(', ')
          .split('[')
          .join(', \'[\', ')
          .split(']')
          .join(', \']\'')
          .split('-')
          .join(', \'-\', ')
          .split('+')
          .join(', \'+\', ')
          .toLowerCase())
        .filter(line => line.length > 0)
        .map(line => `command(${line})`);

      const state = JSON.stringify({
        Objects: this.changedElements,
        Code: code,
      });
      this.changedElements = [];
      this.$socket.emit('setState', state);
    },
    step() {
      this.$socket.emit('step', this.code);
    },
    delayed() {
      this.$socket.emit('emulateDelayed', +this.delay);
    },
    simultaneous() {
      this.$socket.emit('emulateDelayed', 0);
    },
  },
};
