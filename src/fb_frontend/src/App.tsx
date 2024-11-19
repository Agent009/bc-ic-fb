import { Principal } from '@dfinity/principal';
import { Header, Footer } from '@components/Common';

type Props = {
  loggedInPrincipal: Principal
};

function App(props: Props) {

  return (
    <main>
      <Header />
      <Footer />
    </main>
  );
}

export default App;
